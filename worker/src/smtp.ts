import { connect } from 'cloudflare:sockets';

import type { RequiredSmtpSettings } from './admin_settings';
import { HttpError } from './utils';

type SocketLike = ReturnType<typeof connect>;

export type EmailMessage = {
  to: string;
  subject: string;
  text: string;
};

export async function sendEmail(settings: RequiredSmtpSettings, message: EmailMessage): Promise<void> {
  const secureTransport: SocketOptions['secureTransport'] = settings.secureMode === 'tls'
    ? 'on'
    : settings.secureMode === 'starttls'
      ? 'starttls'
      : 'off';
  const socket = connect(
    { hostname: settings.host, port: settings.port },
    { secureTransport, allowHalfOpen: false },
  );
  const client = new SmtpConnection(socket);

  try {
    await client.open();
    await client.readReply([220]);
    await client.command(`EHLO ${smtpDomain(settings.fromEmail)}`, [250]);
    if (settings.secureMode === 'starttls') {
      await client.command('STARTTLS', [220]);
      client.startTls();
      await client.command(`EHLO ${smtpDomain(settings.fromEmail)}`, [250]);
    }
    if (settings.username || settings.password) {
      await client.command(
        `AUTH PLAIN ${base64Encode(`\u0000${settings.username ?? ''}\u0000${settings.password ?? ''}`)}`,
        [235],
      );
    }
    await client.command(`MAIL FROM:<${settings.fromEmail}>`, [250]);
    await client.command(`RCPT TO:<${message.to}>`, [250, 251]);
    await client.command('DATA', [354]);
    await client.write(`${formatMessage(settings, message)}\r\n.\r\n`);
    await client.readReply([250]);
    await client.command('QUIT', [221]);
  } finally {
    await client.close();
  }
}

class SmtpConnection {
  private socket: SocketLike;
  private reader: ReadableStreamDefaultReader<Uint8Array>;
  private writer: WritableStreamDefaultWriter<Uint8Array>;
  private buffer = '';
  private readonly decoder = new TextDecoder();
  private readonly encoder = new TextEncoder();

  constructor(socket: SocketLike) {
    this.socket = socket;
    this.reader = socket.readable.getReader();
    this.writer = socket.writable.getWriter();
  }

  async open(): Promise<void> {
    await this.socket.opened;
  }

  async command(command: string, expectedCodes: readonly number[]): Promise<string> {
    await this.write(`${command}\r\n`);
    return this.readReply(expectedCodes);
  }

  async write(value: string): Promise<void> {
    await this.writer.write(this.encoder.encode(value));
  }

  async readReply(expectedCodes: readonly number[]): Promise<string> {
    const lines: string[] = [];
    while (true) {
      const line = await this.readLine();
      lines.push(line);
      if (/^\d{3} /.test(line)) break;
    }
    const code = Number(lines[lines.length - 1].slice(0, 3));
    const message = lines.join('\n');
    if (!expectedCodes.includes(code)) {
      throw new HttpError(502, `SMTP command failed: ${message}`);
    }
    return message;
  }

  startTls(): void {
    this.reader.releaseLock();
    this.writer.releaseLock();
    this.socket = this.socket.startTls();
    this.reader = this.socket.readable.getReader();
    this.writer = this.socket.writable.getWriter();
  }

  async close(): Promise<void> {
    try {
      this.reader.releaseLock();
    } catch {
      // already released
    }
    try {
      this.writer.releaseLock();
    } catch {
      // already released
    }
    try {
      await this.socket.close();
    } catch {
      // connection may already be closed
    }
  }

  private async readLine(): Promise<string> {
    while (!this.buffer.includes('\n')) {
      const result = await this.reader.read();
      if (result.done) throw new HttpError(502, 'SMTP connection closed unexpectedly');
      this.buffer += this.decoder.decode(result.value, { stream: true });
    }
    const index = this.buffer.indexOf('\n');
    const line = this.buffer.slice(0, index).replace(/\r$/, '');
    this.buffer = this.buffer.slice(index + 1);
    return line;
  }
}

function formatMessage(settings: RequiredSmtpSettings, message: EmailMessage): string {
  const from = settings.fromName
    ? `${quoteDisplayName(settings.fromName)} <${settings.fromEmail}>`
    : settings.fromEmail;
  const headers = [
    `From: ${from}`,
    `To: ${message.to}`,
    `Subject: ${encodeHeader(message.subject)}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
    `Date: ${new Date().toUTCString()}`,
    `Message-ID: <${crypto.randomUUID()}@${smtpDomain(settings.fromEmail)}>`,
  ];
  return `${headers.join('\r\n')}\r\n\r\n${dotStuff(message.text)}`;
}

function dotStuff(value: string): string {
  return value
    .replace(/\r?\n/g, '\r\n')
    .split('\r\n')
    .map((line) => line.startsWith('.') ? `.${line}` : line)
    .join('\r\n');
}

function quoteDisplayName(value: string): string {
  return `"${value.replace(/["\\]/g, '\\$&')}"`;
}

function encodeHeader(value: string): string {
  if (/^[\x20-\x7e]+$/.test(value)) return value;
  return `=?UTF-8?B?${base64Encode(value)}?=`;
}

function base64Encode(value: string): string {
  const bytes = new TextEncoder().encode(value);
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function smtpDomain(email: string): string {
  return email.split('@')[1] || 'form-concierge.local';
}
