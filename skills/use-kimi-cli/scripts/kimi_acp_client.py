#!/usr/bin/env python3
"""
Kimi Code CLI ACP Client

A Python client for communicating with Kimi Code CLI via ACP protocol.

Usage:
    # Start ACP server in one terminal:
    kimi acp
    
    # Use this client in another:
    python kimi_acp_client.py "Your task"
"""

import json
import sys
import uuid
from typing import Optional, Dict, Any, Callable


class KimiACPClient:
    """
    ACP (Agent Client Protocol) client for Kimi Code CLI.
    
    This client communicates with `kimi acp` server via stdin/stdout
    using JSON-RPC 2.0 style messages.
    """
    
    def __init__(self, process=None):
        """
        Initialize the ACP client.
        
        Args:
            process: Optional subprocess.Popen instance of 'kimi acp'.
                    If not provided, the client will start one.
        """
        self.process = process
        self._request_id = 0
        self._started = False
    
    def start(self):
        """Start the ACP server process if not already running."""
        if self.process is None and not self._started:
            import subprocess
            self.process = subprocess.Popen(
                ["kimi", "acp"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1  # Line buffered
            )
            self._started = True
    
    def stop(self):
        """Stop the ACP server process."""
        if self.process and self._started:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except:
                self.process.kill()
            self.process = None
            self._started = False
    
    def _send_request(self, method: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """Send a request to the ACP server."""
        self._request_id += 1
        request = {
            "jsonrpc": "2.0",
            "id": self._request_id,
            "method": method,
            "params": params
        }
        
        request_line = json.dumps(request) + "\n"
        self.process.stdin.write(request_line)
        self.process.stdin.flush()
        
        # Read response
        response_line = self.process.stdout.readline()
        if not response_line:
            raise RuntimeError("ACP server closed connection")
        
        return json.loads(response_line)
    
    def request(
        self,
        prompt: str,
        session_id: Optional[str] = None,
        work_dir: Optional[str] = None,
        yolo: bool = False,
        timeout: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Send a request to the Kimi ACP server.
        
        Args:
            prompt: The task description/prompt
            session_id: Optional session ID for continuing a conversation
            work_dir: Working directory for the agent
            yolo: Auto-approve all actions
            timeout: Request timeout in seconds
        
        Returns:
            Response dict with 'content', 'session_id', etc.
        """
        self.start()
        
        params = {
            "prompt": prompt,
            "yolo": yolo
        }
        
        if session_id:
            params["session_id"] = session_id
        if work_dir:
            params["work_dir"] = work_dir
        if timeout:
            params["timeout"] = timeout
        
        response = self._send_request("agent/request", params)
        
        if "error" in response:
            raise RuntimeError(f"ACP Error: {response['error']}")
        
        return response.get("result", {})
    
    def new_session(
        self,
        prompt: str,
        work_dir: Optional[str] = None,
        yolo: bool = False
    ) -> str:
        """
        Start a new session and return the session ID.
        
        Returns:
            Session ID string
        """
        result = self.request(prompt, work_dir=work_dir, yolo=yolo)
        return result.get("session_id")
    
    def continue_session(
        self,
        session_id: str,
        prompt: str,
        yolo: bool = False
    ) -> str:
        """
        Continue an existing session.
        
        Returns:
            Response content string
        """
        result = self.request(prompt, session_id=session_id, yolo=yolo)
        return result.get("content", "")
    
    def __enter__(self):
        self.start()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()
        return False


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Kimi ACP Client")
    parser.add_argument("prompt", help="Task description")
    parser.add_argument("-w", "--work-dir", help="Working directory")
    parser.add_argument("-y", "--yolo", action="store_true", help="Auto-approve")
    parser.add_argument("-s", "--session", help="Session ID to continue")
    
    args = parser.parse_args()
    
    try:
        with KimiACPClient() as client:
            result = client.request(
                prompt=args.prompt,
                session_id=args.session,
                work_dir=args.work_dir,
                yolo=args.yolo
            )
            print(result.get("content", ""))
            if result.get("session_id") and not args.session:
                print(f"\n[Session ID: {result['session_id']}]", file=sys.stderr)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
