import {
  isToolCallEventType,
  type ExtensionAPI,
  type ExtensionContext,
  type SessionStartEvent,
  type ToolCallEvent,
  type UserBashEvent,
} from "@mariozechner/pi-coding-agent";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { homedir } from "node:os";

type State = { enabled: boolean; strict: boolean; allowList: string[] };

const stateFile = join(homedir(), ".pi", "agent", "bash-approval.json");

function loadState(): State {
  try {
    const parsed = JSON.parse(readFileSync(stateFile, "utf8")) as Partial<State>;
    return {
      enabled: parsed.enabled !== false,
      strict: parsed.strict === true,
      allowList: Array.isArray(parsed.allowList) ? parsed.allowList.filter((command): command is string => typeof command === "string") : [],
    };
  } catch {
    return { enabled: true, strict: false, allowList: [] };
  }
}

function saveState(state: State) {
  mkdirSync(dirname(stateFile), { recursive: true });
  writeFileSync(stateFile, JSON.stringify(state, null, "\t") + "\n", "utf8");
}

function setStatus(ctx: ExtensionContext, state: State): void {
  if (!ctx.hasUI) return;
  const mode = state.strict ? "strict" : "allow-list";
  ctx.ui.setStatus("bash-approval", state.enabled ? `bash approval: on (${mode})` : "bash approval: off");
}

function getFirstShellWord(command: string): string {
  const match = command.trim().match(/^(?:\w+=\S+\s+)*(?:sudo\s+)?([^\s;&|]+)/);
  return match?.[1] ?? "";
}

function splitShellCommands(command: string): string[] {
  const commands: string[] = [];
  let current = "";
  let quote: "'" | '"' | undefined;
  let escaped = false;

  for (let i = 0; i < command.length; i++) {
    const char = command[i];
    const next = command[i + 1];

    if (escaped) {
      current += char;
      escaped = false;
      continue;
    }

    if (char === "\\") {
      current += char;
      escaped = true;
      continue;
    }

    if (quote) {
      current += char;
      if (char === quote) quote = undefined;
      continue;
    }

    if (char === "'" || char === '"') {
      quote = char;
      current += char;
      continue;
    }

    if (char === "&" && next === "&") {
      if (current.trim()) commands.push(current.trim());
      current = "";
      i++;
      continue;
    }

    if (char === "|" || char === ";" || char === "\n") {
      if (current.trim()) commands.push(current.trim());
      current = "";
      if (char === "|" && next === "|") i++;
      continue;
    }

    current += char;
  }

  if (current.trim()) commands.push(current.trim());
  return commands;
}

function hasUnquotedShellSyntax(command: string): boolean {
  let quote: "'" | '"' | undefined;
  let escaped = false;

  for (const char of command) {
    if (escaped) {
      escaped = false;
      continue;
    }

    if (char === "\\") {
      escaped = true;
      continue;
    }

    if (quote) {
      if (char === quote) quote = undefined;
      continue;
    }

    if (char === "'" || char === '"') {
      quote = char;
      continue;
    }

    if (/[`$()<>&]/.test(char)) return true;
  }

  return false;
}

function isSimpleCommand(command: string): boolean {
  return splitShellCommands(command).length === 1 && !hasUnquotedShellSyntax(command);
}

function isAllowedCommand(command: string, allowList: string[]): boolean {
  const trimmed = command.trim();
  if (!trimmed) return false;

  const allowedEntries = allowList.map((allowed) => allowed.trim()).filter(Boolean);
  if (allowedEntries.includes(trimmed)) return true;

  const commands = splitShellCommands(trimmed);
  if (commands.length === 0) return false;

  return commands.every((part) => {
    const firstWord = getFirstShellWord(part);
    return allowedEntries.some((entry) => !entry.includes(" ") && isSimpleCommand(part) && firstWord === entry);
  });
}

type BashApprovalDecision =
  | { action: "approve" }
  | { action: "deny" }
  | { action: "suggest"; command: string };

async function confirmBash(ctx: ExtensionContext, command: string): Promise<BashApprovalDecision> {
  if (!ctx.hasUI) return { action: "deny" };

  const choice = await ctx.ui.select(`Approve bash command?\n${command}`, ["Approve", "Suggest replacement", "Deny"]);

  if (choice === "Approve") return { action: "approve" };

  if (choice === "Suggest replacement") {
    const suggestion = await ctx.ui.input("Suggest bash command", command);
    const trimmed = suggestion?.trim();
    if (trimmed) return { action: "suggest", command: trimmed };
  }

  return { action: "deny" };
}

export default function (pi: ExtensionAPI) {
  const state = loadState();

  pi.on("session_start", async (_event: SessionStartEvent, ctx: ExtensionContext) => {
    setStatus(ctx, state);
  });

  pi.registerCommand("bash-approval", {
    description: "Turn bash command approval on/off and manage allowed commands: /bash-approval [on|off|toggle|status|strict|allow ...]",
    handler: async (args, ctx: ExtensionContext) => {
      const rawArgs = (args || "toggle").trim();
      const [action = "toggle", allowAction, ...rest] = rawArgs.split(/\s+/);
      const normalizedAction = action.toLowerCase();

      if (["on", "enable", "enabled", "yes", "true"].includes(normalizedAction)) {
        state.enabled = true;
      } else if (["off", "disable", "disabled", "no", "false"].includes(normalizedAction)) {
        state.enabled = false;
      } else if (["toggle", ""].includes(normalizedAction)) {
        state.enabled = !state.enabled;
      } else if (["strict", "strict-mode"].includes(normalizedAction)) {
        const strictAction = (allowAction || "toggle").toLowerCase();
        if (["on", "enable", "enabled", "yes", "true"].includes(strictAction)) {
          state.strict = true;
        } else if (["off", "disable", "disabled", "no", "false"].includes(strictAction)) {
          state.strict = false;
        } else if (["toggle", ""].includes(strictAction)) {
          state.strict = !state.strict;
        } else if (!["status", "show"].includes(strictAction)) {
          ctx.ui.notify("Usage: /bash-approval strict [on|off|toggle|status]", "warning");
          return;
        }
      } else if (["allow", "allowlist", "allow-list"].includes(normalizedAction)) {
        const normalizedAllowAction = (allowAction || "list").toLowerCase();
        const command = rest.join(" ").trim();

        if (["list", "status", "show", ""].includes(normalizedAllowAction)) {
          const allowed = state.allowList.length ? state.allowList.map((entry) => `- ${entry}`).join("\n") : "No commands are allowed.";
          ctx.ui.notify(`Allowed bash commands:\n${allowed}`, "info");
          return;
        }

        if (["add", "append"].includes(normalizedAllowAction)) {
          if (!command) {
            ctx.ui.notify("Usage: /bash-approval allow add <command>", "warning");
            return;
          }
          if (!state.allowList.includes(command)) state.allowList.push(command);
          saveState(state);
          ctx.ui.notify(`Allowed bash command: ${command}`, "info");
          return;
        }

        if (["remove", "rm", "delete", "del"].includes(normalizedAllowAction)) {
          if (!command) {
            ctx.ui.notify("Usage: /bash-approval allow remove <command>", "warning");
            return;
          }
          state.allowList = state.allowList.filter((entry) => entry !== command);
          saveState(state);
          ctx.ui.notify(`Removed allowed bash command: ${command}`, "info");
          return;
        }

        if (["clear", "reset"].includes(normalizedAllowAction)) {
          state.allowList = [];
          saveState(state);
          ctx.ui.notify("Cleared allowed bash commands.", "info");
          return;
        }

        ctx.ui.notify("Usage: /bash-approval allow [list|add <command>|remove <command>|clear]", "warning");
        return;
      } else if (!["status", "show"].includes(normalizedAction)) {
        ctx.ui.notify("Usage: /bash-approval [on|off|toggle|status|strict [on|off|toggle|status]|allow [list|add <command>|remove <command>|clear]]", "warning");
        return;
      }
      saveState(state);
      setStatus(ctx, state);
      ctx.ui.notify(`Bash approval is ${state.enabled ? "ON" : "OFF"}. Strict mode is ${state.strict ? "ON" : "OFF"}. ${state.allowList.length} allowed command(s).`, "info");
    },
  });

  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    if (!state.enabled || !isToolCallEventType("bash", event)) return undefined;
    if (!state.strict && isAllowedCommand(event.input.command, state.allowList)) return undefined;

    const decision = await confirmBash(ctx, event.input.command);
    if (decision.action === "approve") return undefined;
    if (decision.action === "suggest") {
      return {
        block: true,
        reason: `Bash command blocked by approval gate. Continue the conversation and follow the user's suggestion instead of stopping. User suggestion: ${decision.command}`,
      };
    }

    return { block: true, reason: "Bash command blocked by approval gate" };
  });

  pi.on("user_bash", async (event: UserBashEvent, ctx: ExtensionContext) => {
    if (!state.enabled) return undefined;
    if (!state.strict && isAllowedCommand(event.command, state.allowList)) return undefined;

    const decision = await confirmBash(ctx, event.command);
    if (decision.action === "approve") return undefined;

    if (decision.action === "suggest") {
      return {
        result: {
          output: `Bash command blocked by approval gate. Continue the conversation and follow the user's suggestion instead of stopping. User suggestion: ${decision.command}`,
          exitCode: 1,
          cancelled: false,
          truncated: false,
        },
      };
    }

    return {
      result: {
        output: "Bash command blocked by approval gate.",
        exitCode: 1,
        cancelled: false,
        truncated: false,
      },
    };
  });
}
