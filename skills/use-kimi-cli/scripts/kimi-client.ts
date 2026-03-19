/**
 * Kimi Code CLI TypeScript Client
 * 
 * A TypeScript client for calling Kimi Code CLI from other agents.
 * Supports both subprocess and ACP modes.
 * 
 * Usage:
 *   import { KimiSubprocessClient, KimiACPClient } from './kimi-client';
 * 
 *   // Subprocess mode (simple)
 *   const client = new KimiSubprocessClient();
 *   const result = await client.call("Your task");
 * 
 *   // ACP mode (multi-session)
 *   const acp = new KimiACPClient();
 *   await acp.start();
 *   const result = await acp.request("Your task");
 *   await acp.stop();
 */

import { spawn, ChildProcess } from 'child_process';
import { promisify } from 'util';
import { exec } from 'child_process';

const execAsync = promisify(exec);

export interface KimiOptions {
  workDir?: string;
  yolo?: boolean;
  model?: string;
  addDirs?: string[];
  timeout?: number;
}

export interface KimiResult {
  success: boolean;
  content: string;
  error?: string;
  exitCode: number;
  sessionId?: string;
}

/**
 * Simple subprocess-based client for Kimi Code CLI.
 * Best for one-off tasks.
 */
export class KimiSubprocessClient {
  /**
   * Call Kimi with a task using subprocess mode.
   */
  async call(task: string, options: KimiOptions = {}): Promise<KimiResult> {
    const args = ['--print', '--quiet'];

    if (options.workDir) {
      args.push('-w', options.workDir);
    }

    if (options.addDirs) {
      for (const dir of options.addDirs) {
        args.push('--add-dir', dir);
      }
    }

    if (options.yolo) {
      args.push('-y');
    }

    if (options.model) {
      args.push('-m', options.model);
    }

    args.push('--prompt', task);

    try {
      const { stdout, stderr } = await execAsync(
        `kimi ${args.map(a => `"${a.replace(/"/g, '\\"')}"`).join(' ')}`,
        { timeout: (options.timeout || 300) * 1000 }
      );

      return {
        success: true,
        content: stdout,
        exitCode: 0
      };
    } catch (error: any) {
      return {
        success: false,
        content: error.stdout || '',
        error: error.stderr || error.message,
        exitCode: error.code || -1
      };
    }
  }

  /**
   * Quick helper to run a simple task.
   */
  static async quick(task: string, workDir?: string): Promise<string> {
    const client = new KimiSubprocessClient();
    const result = await client.call(task, { workDir });
    if (!result.success) {
      throw new Error(result.error || 'Unknown error');
    }
    return result.content;
  }
}

interface ACPRequest {
  jsonrpc: '2.0';
  id: number;
  method: string;
  params: Record<string, any>;
}

interface ACPResponse {
  jsonrpc: '2.0';
  id: number;
  result?: any;
  error?: {
    code: number;
    message: string;
  };
}

/**
 * ACP (Agent Client Protocol) client for Kimi.
 * Supports multi-session communication.
 */
export class KimiACPClient {
  private process?: ChildProcess;
  private requestId = 0;
  private pendingRequests = new Map<number, {
    resolve: (value: ACPResponse) => void;
    reject: (reason: Error) => void;
  }>();

  /**
   * Start the ACP server process.
   */
  async start(): Promise<void> {
    if (this.process) {
      return;
    }

    this.process = spawn('kimi', ['acp'], {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    this.process.stdout?.on('data', (data: Buffer) => {
      const lines = data.toString().trim().split('\n');
      for (const line of lines) {
        try {
          const response: ACPResponse = JSON.parse(line);
          const pending = this.pendingRequests.get(response.id);
          if (pending) {
            pending.resolve(response);
            this.pendingRequests.delete(response.id);
          }
        } catch (e) {
          console.error('Failed to parse ACP response:', line);
        }
      }
    });

    this.process.stderr?.on('data', (data: Buffer) => {
      console.error('Kimi ACP stderr:', data.toString());
    });

    this.process.on('close', (code) => {
      if (code !== 0) {
        console.error(`Kimi ACP process exited with code ${code}`);
      }
    });
  }

  /**
   * Stop the ACP server process.
   */
  async stop(): Promise<void> {
    if (!this.process) {
      return;
    }

    this.process.kill();
    
    // Reject all pending requests
    for (const [id, pending] of this.pendingRequests) {
      pending.reject(new Error('ACP client stopped'));
    }
    this.pendingRequests.clear();
    
    this.process = undefined;
  }

  /**
   * Send a request to the ACP server.
   */
  async request(
    prompt: string,
    options: KimiOptions & { sessionId?: string } = {}
  ): Promise<KimiResult> {
    if (!this.process) {
      await this.start();
    }

    this.requestId++;
    const id = this.requestId;

    const params: Record<string, any> = {
      prompt,
      yolo: options.yolo ?? false
    };

    if (options.sessionId) {
      params.session_id = options.sessionId;
    }
    if (options.workDir) {
      params.work_dir = options.workDir;
    }
    if (options.timeout) {
      params.timeout = options.timeout;
    }

    const request: ACPRequest = {
      jsonrpc: '2.0',
      id,
      method: 'agent/request',
      params
    };

    return new Promise((resolve, reject) => {
      // Set timeout
      const timeoutMs = (options.timeout || 300) * 1000;
      const timeoutId = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Request timeout after ${timeoutMs}ms`));
      }, timeoutMs);

      // Store pending request
      this.pendingRequests.set(id, {
        resolve: (response: ACPResponse) => {
          clearTimeout(timeoutId);
          
          if (response.error) {
            resolve({
              success: false,
              content: '',
              error: response.error.message,
              exitCode: response.error.code
            });
          } else {
            resolve({
              success: true,
              content: response.result?.content || '',
              exitCode: 0,
              sessionId: response.result?.session_id
            });
          }
        },
        reject: (error: Error) => {
          clearTimeout(timeoutId);
          reject(error);
        }
      });

      // Send request
      const requestLine = JSON.stringify(request) + '\n';
      this.process!.stdin!.write(requestLine);
    });
  }

  /**
   * Create a new session and return the session ID.
   */
  async createSession(
    initialPrompt: string,
    options: Omit<KimiOptions, 'sessionId'> = {}
  ): Promise<string> {
    const result = await this.request(initialPrompt, options);
    if (!result.success) {
      throw new Error(result.error || 'Failed to create session');
    }
    if (!result.sessionId) {
      throw new Error('No session ID returned');
    }
    return result.sessionId;
  }

  /**
   * Continue an existing session.
   */
  async continueSession(
    sessionId: string,
    prompt: string,
    options: Omit<KimiOptions, 'sessionId'> = {}
  ): Promise<string> {
    const result = await this.request(prompt, { ...options, sessionId });
    if (!result.success) {
      throw new Error(result.error || 'Failed to continue session');
    }
    return result.content;
  }
}

// Example usage
if (require.main === module) {
  (async () => {
    // Subprocess example
    console.log('=== Subprocess Mode ===');
    const subClient = new KimiSubprocessClient();
    const result = await subClient.call("List all files in current directory");
    console.log('Success:', result.success);
    console.log('Content:', result.content.substring(0, 200));

    // ACP example (commented out as it requires user interaction)
    /*
    console.log('\n=== ACP Mode ===');
    const acpClient = new KimiACPClient();
    await acpClient.start();
    try {
      const sessionId = await acpClient.createSession(
        "Analyze the project structure"
      );
      console.log('Session ID:', sessionId);
      
      const followUp = await acpClient.continueSession(
        sessionId,
        "Now find all TODO comments"
      );
      console.log('Follow-up result:', followUp.substring(0, 200));
    } finally {
      await acpClient.stop();
    }
    */
  })();
}
