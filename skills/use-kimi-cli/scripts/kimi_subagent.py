#!/usr/bin/env python3
"""
Kimi Code CLI Subagent Wrapper

A simple wrapper to call Kimi Code CLI as a subagent from other Python code.

Usage:
    python kimi_subagent.py "Your task description"
    python kimi_subagent.py -w /path/to/project -y "Your task"
"""

import argparse
import subprocess
import sys
from typing import Optional


def call_kimi(
    task: str,
    work_dir: Optional[str] = None,
    yolo: bool = False,
    model: Optional[str] = None,
    add_dirs: Optional[list] = None,
    timeout: int = 300
) -> tuple[int, str, str]:
    """
    Call Kimi Code CLI as a subagent.
    
    Args:
        task: The task description/prompt
        work_dir: Working directory for the agent
        yolo: Auto-approve all actions
        model: Model to use (e.g., "moonshot-v1-32k")
        add_dirs: Additional directories to include in scope
        timeout: Timeout in seconds
    
    Returns:
        Tuple of (exit_code, stdout, stderr)
    """
    cmd = ["kimi", "--print", "--quiet"]
    
    if work_dir:
        cmd.extend(["-w", work_dir])
    
    if add_dirs:
        for d in add_dirs:
            cmd.extend(["--add-dir", d])
    
    if yolo:
        cmd.append("-y")
    
    if model:
        cmd.extend(["-m", model])
    
    cmd.extend(["--prompt", task])
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", f"Timeout after {timeout} seconds"
    except FileNotFoundError:
        return -1, "", "kimi command not found. Is Kimi CLI installed?"
    except Exception as e:
        return -1, "", str(e)


def main():
    parser = argparse.ArgumentParser(
        description="Call Kimi Code CLI as a subagent"
    )
    parser.add_argument(
        "task",
        help="Task description/prompt for Kimi"
    )
    parser.add_argument(
        "-w", "--work-dir",
        help="Working directory for the agent"
    )
    parser.add_argument(
        "--add-dir",
        action="append",
        dest="add_dirs",
        help="Additional directory to include (can be used multiple times)"
    )
    parser.add_argument(
        "-y", "--yolo",
        action="store_true",
        help="Auto-approve all actions"
    )
    parser.add_argument(
        "-m", "--model",
        help="Model to use (e.g., moonshot-v1-32k)"
    )
    parser.add_argument(
        "-t", "--timeout",
        type=int,
        default=300,
        help="Timeout in seconds (default: 300)"
    )
    
    args = parser.parse_args()
    
    exit_code, stdout, stderr = call_kimi(
        task=args.task,
        work_dir=args.work_dir,
        yolo=args.yolo,
        model=args.model,
        add_dirs=args.add_dirs,
        timeout=args.timeout
    )
    
    if stdout:
        print(stdout)
    
    if stderr:
        print(stderr, file=sys.stderr)
    
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
