#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import http.client
import json
import os
import socket
import sys
import time
import urllib.parse
import urllib.request

from playwright.sync_api import sync_playwright

# =========================
# 你的配置
# =========================
GROUP_NAME = "Proxy"
CANDIDATES = [
    "US-A-x0",
    "US-B-x1",
    "US-C-x1",
    "US-D-x1",
]

PROVIDERS_TO_REFRESH = [
    # "provider1",
]

LOCAL_MIXED_PROXY = "http://127.0.0.1:10808"

# 基础连通性探测
PROBE_URL = "https://cp.cloudflare.com/generate_204"
DELAY_TEST_URL = "https://www.gstatic.com/generate_204"

# 真正关心的目标站点
TARGET_URL = "https://chatgpt.com"

CHECK_INTERVAL_SEC = 10
PROBE_TIMEOUT_SEC = 6
DELAY_TIMEOUT_MS = 5000
CONTROLLER_TIMEOUT_SEC = 10
BROWSER_TIMEOUT_MS = 15000

# 基础网络连续失败几次后切换
FAIL_STREAK_BEFORE_SWITCH = 2

# 目标站点“明确网络失败”连续几次后切换
TARGET_FAIL_STREAK_BEFORE_SWITCH = 3

SWITCH_COOLDOWN_SEC = 20
AFTER_SWITCH_SETTLE_SEC = 4
MAX_ACCEPTABLE_DELAY_MS = 1500

AUTO_REFRESH_PROVIDERS = True
AUTO_RESTART_CORE = False

# 第一次建议先 True，只看日志不真的切
DRY_RUN = True

UNIX_SOCKET_CANDIDATES = [
    "/tmp/verge/verge-mihomo.sock",
    "/tmp/mihomo.sock",
]

CONTROLLER_HTTP = "http://127.0.0.1:9097"
CONTROLLER_SECRET = ""

LOG_PREFIX = "[clash-watchdog]"


def log(msg: str) -> None:
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"{LOG_PREFIX} {ts} | {msg}", flush=True)


def q(name: str) -> str:
    return urllib.parse.quote(name, safe="")


class UnixSocketHTTPConnection(http.client.HTTPConnection):
    def __init__(self, unix_socket_path: str, timeout: int = 10):
        super().__init__("localhost", timeout=timeout)
        self.unix_socket_path = unix_socket_path

    def connect(self) -> None:
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(self.timeout)
        self.sock.connect(self.unix_socket_path)


class MihomoController:
    def __init__(self, unix_socket_candidates, http_base: str, secret: str):
        self.unix_socket = next((p for p in unix_socket_candidates if os.path.exists(p)), None)
        parsed = urllib.parse.urlparse(http_base)
        self.http_host = parsed.hostname or "127.0.0.1"
        self.http_port = parsed.port or 9097
        self.secret = secret or ""

    def describe(self) -> str:
        if self.unix_socket:
            return f"unix://{self.unix_socket}"
        return f"http://{self.http_host}:{self.http_port}"

    def _request(self, method: str, path: str, params=None, body=None):
        if params:
            path = f"{path}?{urllib.parse.urlencode(params, doseq=True)}"

        headers = {"Accept": "application/json"}
        data = None

        if body is not None:
            headers["Content-Type"] = "application/json"
            data = json.dumps(body).encode("utf-8")

        if self.secret and not self.unix_socket:
            headers["Authorization"] = f"Bearer {self.secret}"

        if self.unix_socket:
            conn = UnixSocketHTTPConnection(self.unix_socket, timeout=CONTROLLER_TIMEOUT_SEC)
        else:
            conn = http.client.HTTPConnection(self.http_host, self.http_port, timeout=CONTROLLER_TIMEOUT_SEC)

        try:
            conn.request(method, path, body=data, headers=headers)
            resp = conn.getresponse()
            raw = resp.read()
        finally:
            try:
                conn.close()
            except Exception:
                pass

        text = raw.decode("utf-8", errors="replace")
        if resp.status >= 400:
            raise RuntimeError(f"{method} {path} -> {resp.status}: {text[:300]}")

        if not text.strip():
            return None

        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return text

    def version(self):
        return self._request("GET", "/version")

    def get_proxy(self, name: str):
        return self._request("GET", f"/proxies/{q(name)}")

    def current_selection(self, group_name: str):
        data = self.get_proxy(group_name)
        if isinstance(data, dict):
            return data.get("now")
        return None

    def list_group_members(self, group_name: str):
        data = self.get_proxy(group_name)
        if isinstance(data, dict) and isinstance(data.get("all"), list):
            return [x for x in data["all"] if isinstance(x, str)]
        return []

    def test_proxy_delay(self, name: str, url: str, timeout_ms: int):
        return self._request(
            "GET",
            f"/proxies/{q(name)}/delay",
            params={"url": url, "timeout": timeout_ms},
        )

    def switch_selector(self, group_name: str, target_name: str):
        return self._request(
            "PUT",
            f"/proxies/{q(group_name)}",
            body={"name": target_name},
        )

    def refresh_provider(self, provider_name: str):
        return self._request("PUT", f"/providers/proxies/{q(provider_name)}")

    def healthcheck_provider(self, provider_name: str):
        return self._request("GET", f"/providers/proxies/{q(provider_name)}/healthcheck")

    def restart_core(self):
        return self._request("POST", "/restart")


def extract_delay_ms(api_result):
    if isinstance(api_result, dict):
        for key in ("delay", "meanDelay"):
            value = api_result.get(key)
            if isinstance(value, int) and value > 0:
                return value
    return None


def real_probe_via_local_proxy():
    proxy_handler = urllib.request.ProxyHandler({
        "http": LOCAL_MIXED_PROXY,
        "https": LOCAL_MIXED_PROXY,
    })
    opener = urllib.request.build_opener(proxy_handler)
    req = urllib.request.Request(
        PROBE_URL,
        headers={"User-Agent": "clash-watchdog/1.0"},
    )

    start = time.perf_counter()
    try:
        with opener.open(req, timeout=PROBE_TIMEOUT_SEC) as resp:
            resp.read(1)
            elapsed_ms = int((time.perf_counter() - start) * 1000)
            status = getattr(resp, "status", 0)
            ok = status == 204 or (200 <= status < 400)
            return ok, elapsed_ms, f"HTTP {status}"
    except Exception as e:
        return False, None, f"{type(e).__name__}: {e}"


def classify_browser_exception(detail: str):
    lowered = detail.lower()

    network_error_keywords = [
        "timeout",
        "timed out",
        "net::err_proxy_connection_failed",
        "net::err_tunnel_connection_failed",
        "net::err_connection_closed",
        "net::err_connection_reset",
        "net::err_name_not_resolved",
        "net::err_internet_disconnected",
        "net::err_connection_timed_out",
        "net::err_address_unreachable",
        "net::err_network_changed",
        "net::err_http2_protocol_error",
    ]

    if any(x in lowered for x in network_error_keywords):
        return False

    return None


def probe_target_via_browser():
    """
    返回三态：
    - True: 目标站点正常
    - None: 可达但不确定 / challenge / blocked / 自动化不可判定，不触发切换
    - False: 明确网络失败，可累计后切换
    """
    start = time.perf_counter()
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True,
                proxy={"server": LOCAL_MIXED_PROXY},
            )
            page = browser.new_page()
            page.goto(TARGET_URL, wait_until="domcontentloaded", timeout=BROWSER_TIMEOUT_MS)

            title = (page.title() or "").lower()
            url = (page.url or "").lower()

            body_text = ""
            try:
                body_text = page.locator("body").inner_text(timeout=3000).lower()
            except Exception:
                pass

            page_html = ""
            try:
                page_html = page.content().lower()
            except Exception:
                pass

            browser.close()

        elapsed_ms = int((time.perf_counter() - start) * 1000)

        bad_signals = [
            "cf-mitigated",
            "attention required",
            "access denied",
            "forbidden",
            "verify you are human",
            "challenge",
            "checking your browser",
        ]

        good_signals = [
            "chatgpt",
            "log in",
            "sign up",
            "continue with google",
            "continue with apple",
            "continue with email",
        ]

        combined = "\n".join([title, url, body_text[:4000], page_html[:4000]])

        if any(x in combined for x in bad_signals):
            return None, elapsed_ms, "challenge_or_blocked"

        if any(x in combined for x in good_signals):
            return True, elapsed_ms, "ok"

        return None, elapsed_ms, f"uncertain title={title[:80]!r}"

    except Exception as e:
        elapsed_ms = int((time.perf_counter() - start) * 1000)
        detail = f"{type(e).__name__}: {e}"
        state = classify_browser_exception(detail)
        return state, elapsed_ms, detail


def resolve_candidates(ctl: MihomoController):
    if CANDIDATES:
        return list(CANDIDATES)

    auto = ctl.list_group_members(GROUP_NAME)
    skip = {"DIRECT", "REJECT", "PASS", "GLOBAL", "COMPATIBLE"}
    return [x for x in auto if x not in skip]


def rank_candidates(ctl: MihomoController, candidates):
    ranked = []
    for name in candidates:
        try:
            result = ctl.test_proxy_delay(name, DELAY_TEST_URL, DELAY_TIMEOUT_MS)
            delay = extract_delay_ms(result)
            if delay is None:
                log(f"测速失败: {name} -> {result}")
                continue
            ranked.append((delay, name))
            log(f"测速成功: {name} -> {delay}ms")
        except Exception as e:
            log(f"测速异常: {name} -> {type(e).__name__}: {e}")

    ranked.sort(key=lambda x: x[0])
    return ranked


def choose_switch_target(ranked, current_name: str):
    if not ranked:
        return None

    healthy = [item for item in ranked if item[0] <= MAX_ACCEPTABLE_DELAY_MS]
    pool = healthy if healthy else ranked

    for _, name in pool:
        if name != current_name:
            return name

    return None


def refresh_providers(ctl: MihomoController):
    if not AUTO_REFRESH_PROVIDERS or not PROVIDERS_TO_REFRESH:
        return

    for provider in PROVIDERS_TO_REFRESH:
        try:
            if DRY_RUN:
                log(f"[DRY RUN] 将刷新 provider: {provider}")
                continue
            ctl.refresh_provider(provider)
            try:
                ctl.healthcheck_provider(provider)
            except Exception as e:
                log(f"provider healthcheck 失败（可忽略）: {provider} -> {e}")
            log(f"已刷新 provider: {provider}")
        except Exception as e:
            log(f"刷新 provider 失败: {provider} -> {type(e).__name__}: {e}")


def maybe_switch(ctl: MihomoController, reason: str, current: str):
    candidates = resolve_candidates(ctl)
    if not candidates:
        log(f"{reason} | 没有可用候选节点")
        refresh_providers(ctl)
        if AUTO_RESTART_CORE and not DRY_RUN:
            try:
                ctl.restart_core()
                log("已重启 core")
            except Exception as e:
                log(f"重启 core 失败: {e}")
        return False, None

    ranked = rank_candidates(ctl, candidates)
    if ranked:
        preview = ", ".join(f"{name}:{delay}ms" for delay, name in ranked[:5])
        log(f"候选排名(top5) => {preview}")
    else:
        log(f"{reason} | 所有候选节点测速都失败")
        refresh_providers(ctl)
        if AUTO_RESTART_CORE and not DRY_RUN:
            try:
                ctl.restart_core()
                log("已重启 core")
            except Exception as e:
                log(f"重启 core 失败: {e}")
        return False, None

    target = choose_switch_target(ranked, current)
    if not target:
        log(f"{reason} | 没有比当前更合适的切换目标")
        refresh_providers(ctl)
        return False, None

    if DRY_RUN:
        log(f"[DRY RUN] 因 {reason} 将切换 {GROUP_NAME}: {current} -> {target}")
    else:
        ctl.switch_selector(GROUP_NAME, target)
        log(f"因 {reason} 已切换 {GROUP_NAME}: {current} -> {target}")
        time.sleep(AFTER_SWITCH_SETTLE_SEC)

    return True, target


def main():
    ctl = MihomoController(
        unix_socket_candidates=UNIX_SOCKET_CANDIDATES,
        http_base=CONTROLLER_HTTP,
        secret=CONTROLLER_SECRET,
    )

    log(f"controller = {ctl.describe()}")
    try:
        ver = ctl.version()
        log(f"mihomo version = {ver}")
    except Exception as e:
        log(f"无法连接 controller，请先确认 Clash Verge Rev 已启动: {e}")
        sys.exit(1)

    network_fail_streak = 0
    target_fail_streak = 0
    last_switch_at = 0.0

    while True:
        try:
            current = None
            try:
                current = ctl.current_selection(GROUP_NAME)
            except Exception as e:
                log(f"读取当前组状态失败: {e}")

            # 1) 基础连通性检测
            ok_net, probe_ms, net_detail = real_probe_via_local_proxy()

            if not ok_net:
                network_fail_streak += 1
                log(f"基础探测失败 | current={current} streak={network_fail_streak} detail={net_detail}")

                if network_fail_streak >= FAIL_STREAK_BEFORE_SWITCH:
                    if time.time() - last_switch_at >= SWITCH_COOLDOWN_SEC:
                        changed, _ = maybe_switch(ctl, "基础连通性失败", current)
                        if changed:
                            last_switch_at = time.time()
                            network_fail_streak = 0
                            target_fail_streak = 0
                    else:
                        log("还在冷却期内，先不切换")

                time.sleep(CHECK_INTERVAL_SEC)
                continue

            network_fail_streak = 0
            log(f"基础探测成功 | current={current} probe={probe_ms}ms detail={net_detail}")

            # 2) 目标站点浏览器探测
            ok_target, target_ms, target_detail = probe_target_via_browser()

            if ok_target is True:
                target_fail_streak = 0
                log(f"目标站点正常 | target={TARGET_URL} current={current} browser={target_ms}ms detail={target_detail}")

            elif ok_target is False:
                target_fail_streak += 1
                log(f"目标站点网络异常 | target={TARGET_URL} current={current} streak={target_fail_streak} detail={target_detail}")

                if target_fail_streak >= TARGET_FAIL_STREAK_BEFORE_SWITCH:
                    if time.time() - last_switch_at >= SWITCH_COOLDOWN_SEC:
                        changed, _ = maybe_switch(ctl, f"目标站点网络异常: {TARGET_URL}", current)
                        if changed:
                            last_switch_at = time.time()
                            network_fail_streak = 0
                            target_fail_streak = 0
                    else:
                        log("还在冷却期内，先不切换")

            else:
                log(f"目标站点状态未知 | target={TARGET_URL} current={current} browser={target_ms}ms detail={target_detail}")

            time.sleep(CHECK_INTERVAL_SEC)

        except KeyboardInterrupt:
            log("收到 Ctrl+C，退出。")
            break
        except Exception as e:
            log(f"主循环异常: {type(e).__name__}: {e}")
            time.sleep(CHECK_INTERVAL_SEC)


if __name__ == "__main__":
    main()
