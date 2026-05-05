import { isToolCallEventType, type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { homedir } from "node:os";

type State = { enabled: boolean };

const stateFile = join(homedir(), ".pi", "agent", "bash-approval.json");

function loadState(): State {
  try {
    const parsed = JSON.parse(readFileSync(stateFile, "utf8")) as Partial<State>;
    return { enabled: parsed.enabled !== false };
  } catch {
    return { enabled: true };
  }
}

function saveState(state: State) {
  mkdirSync(dirname(stateFile), { recursive: true });
  writeFileSync(stateFile, JSON.stringify(state, null, "\t") + "\n", "utf8");
}

function setStatus(ctx: ExtensionContext, enabled: boolean): void {
  if (!ctx.hasUI) return;
  ctx.ui.setStatus("bash-approval", enabled ? "bash approval: on" : "bash approval: off");
}

async function confirmBash(ctx: ExtensionContext, command: string): Promise<boolean> {
  if (!ctx.hasUI) return false;
  return await ctx.ui.confirm("Approve bash command?", command);
}

export default function (pi: ExtensionAPI) {
  const state = loadState();

  pi.on("session_start", async (_event, ctx: ExtensionContext) => {
    setStatus(ctx, state.enabled);
  });

  pi.registerCommand("bash-approval", {
    description: "Turn bash command approval on/off: /bash-approval [on|off|toggle|status]",
    handler: async (args, ctx: ExtensionContext) => {
      const action = (args || "toggle").trim().toLowerCase();

      if (["on", "enable", "enabled", "yes", "true"].includes(action)) {
        state.enabled = true;
      } else if (["off", "disable", "disabled", "no", "false"].includes(action)) {
        state.enabled = false;
      } else if (["toggle", ""].includes(action)) {
        state.enabled = !state.enabled;
      } else if (!["status", "show"].includes(action)) {
        ctx.ui.notify("Usage: /bash-approval [on|off|toggle|status]", "warning");
        return;
      }
      saveState(state);
      setStatus(ctx, state.enabled);
      ctx.ui.notify(`Bash approval is ${state.enabled ? "ON" : "OFF"}.`, "info");
    },
  });

  pi.on("tool_call", async (event, ctx: ExtensionContext) => {
    if (!state.enabled || !isToolCallEventType("bash", event)) return undefined;

    const ok = await confirmBash(ctx, event.input.command);
    if (!ok) return { block: true, reason: "Bash command blocked by approval gate" };

    return undefined;
  });

  pi.on("user_bash", async (event, ctx: ExtensionContext) => {
    if (!state.enabled) return undefined;

    const ok = await confirmBash(ctx, event.command);
    if (ok) return undefined;

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
