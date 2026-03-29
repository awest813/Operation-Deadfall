#!/usr/bin/env python3
"""
Graphical setup helper for Operation Deadfall (Linux): check nzp/, install build
dependencies, build the engine, and launch the game. Run via ./install_gui.sh
from the repository root.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import threading
from pathlib import Path
from tkinter import (
    BOTH,
    END,
    LEFT,
    RIGHT,
    Button,
    Checkbutton,
    Frame,
    IntVar,
    Label,
    Radiobutton,
    Scrollbar,
    StringVar,
    Text,
    Tk,
    messagebox,
)

ROOT = Path(__file__).resolve().parent.parent


def nzp_status() -> tuple[bool, str]:
    inside = ROOT / "nzp"
    parent = ROOT.parent / "nzp"
    if inside.is_dir() and any(inside.iterdir()):
        return True, f"Found game data: {inside}"
    if inside.is_dir():
        return False, f"nzp/ exists but looks empty: {inside}"
    if parent.is_dir() and any(parent.iterdir()):
        return True, f"Found game data: {parent} (next to repo)"
    if parent.is_dir():
        return False, f"../nzp exists but looks empty: {parent}"
    return False, "Missing nzp/ — add NZ:P game data (see README Quick Start)."


def open_terminal_bash(command: str) -> None:
    """Run a bash command in a new terminal (for sudo/password prompts)."""
    inner = f"cd {sh_quote(str(ROOT))} && {command}; echo; read -rp 'Press Enter to close… ' _"
    if shutil.which("x-terminal-emulator"):
        subprocess.Popen(["x-terminal-emulator", "-e", "bash", "-lc", inner])
        return
    if shutil.which("gnome-terminal"):
        subprocess.Popen(
            ["gnome-terminal", "--", "bash", "-lc", inner],
        )
        return
    if shutil.which("konsole"):
        subprocess.Popen(["konsole", "-e", "bash", "-lc", inner])
        return
    if shutil.which("xfce4-terminal"):
        subprocess.Popen(["xfce4-terminal", "-e", f"bash -lc {sh_quote(inner)}"])
        return
    if shutil.which("xterm"):
        subprocess.Popen(["xterm", "-e", "bash", "-lc", inner])
        return
    messagebox.showerror(
        "No terminal found",
        "Install xterm, gnome-terminal, or another terminal emulator, "
        "or run ./scripts/install-linux-build-deps.sh from a terminal.",
    )


def sh_quote(s: str) -> str:
    return "'" + s.replace("'", "'\"'\"'") + "'"


class InstallApp:
    def __init__(self) -> None:
        self.tk = Tk()
        self.tk.title("Operation Deadfall — Setup")
        self.tk.minsize(520, 420)

        self.docker_var = IntVar(value=0)
        self.package_var = IntVar(value=1)
        self.preset_var = StringVar(value="linux64")

        head = Label(
            self.tk,
            text="First-time setup: install build packages, build the engine, then run the game.",
            wraplength=480,
            justify="left",
        )
        head.pack(padx=12, pady=(12, 6), anchor="w")

        self.status_label = Label(self.tk, text="", wraplength=480, justify="left")
        self.status_label.pack(padx=12, pady=4, anchor="w")

        opts = Frame(self.tk)
        opts.pack(padx=12, pady=6, fill="x")

        Label(opts, text="Build preset:").pack(side=LEFT)
        for val, label in (
            ("linux64", "Linux 64-bit (SDL2)"),
            ("linux64-nosdl", "Linux 64-bit (no SDL)"),
        ):
            Radiobutton(
                opts,
                text=label,
                variable=self.preset_var,
                value=val,
            ).pack(side=LEFT, padx=(8, 0))

        checks = Frame(self.tk)
        checks.pack(padx=12, pady=4, anchor="w")
        Checkbutton(
            checks,
            text="Use Docker build (motolegacy/fteqw image)",
            variable=self.docker_var,
        ).pack(anchor="w")
        Checkbutton(
            checks,
            text="Package output to engine/dist/<preset>/",
            variable=self.package_var,
        ).pack(anchor="w")

        btn_row = Frame(self.tk)
        btn_row.pack(padx=12, pady=8, fill="x")

        Button(
            btn_row,
            text="Install build dependencies…",
            command=self.on_install_deps,
        ).pack(side=LEFT, padx=(0, 6))

        Button(
            btn_row,
            text="Build engine",
            command=self.on_build,
        ).pack(side=LEFT, padx=6)

        Button(
            btn_row,
            text="Run game",
            command=self.on_run_game,
        ).pack(side=LEFT, padx=6)

        Button(
            btn_row,
            text="Open repo folder",
            command=self.on_open_folder,
        ).pack(side=LEFT, padx=6)

        log_frame = Frame(self.tk)
        log_frame.pack(padx=12, pady=(4, 12), fill=BOTH, expand=True)

        scroll = Scrollbar(log_frame)
        scroll.pack(side=RIGHT, fill="y")

        self.log = Text(log_frame, height=12, yscrollcommand=scroll.set, wrap="word")
        self.log.pack(side=LEFT, fill=BOTH, expand=True)
        scroll.config(command=self.log.yview)

        self.refresh_status()
        self.log_insert(
            "This window runs build commands from the repo root.\n"
            "“Install build dependencies” opens a terminal (you may be prompted for sudo).\n"
        )

    def log_insert(self, s: str) -> None:
        self.log.insert(END, s)
        self.log.see(END)

    def refresh_status(self) -> None:
        ok, msg = nzp_status()
        self.status_label.config(
            text=msg,
            fg="#0a6b0a" if ok else "#a02020",
        )

    def on_install_deps(self) -> None:
        if sys.platform != "linux":
            messagebox.showinfo(
                "Linux only",
                "The dependency script is for Linux. On Windows use MSYS2 — see BUILD.md.",
            )
            return
        open_terminal_bash("./scripts/install-linux-build-deps.sh")

    def on_build(self) -> None:
        if sys.platform != "linux" and sys.platform != "darwin":
            messagebox.showinfo(
                "Build",
                "On Windows, use build.bat or build_engine.cmd from BUILD.md.",
            )
            return

        parts = [str(ROOT / "build.sh"), "--preset", self.preset_var.get()]
        if self.docker_var.get():
            parts.append("--docker")
        if self.package_var.get():
            parts.append("--package")
        self.log_insert(f"\n$ {' '.join(parts)}\n")

        def worker() -> None:
            proc = subprocess.Popen(
                parts,
                cwd=str(ROOT),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            assert proc.stdout is not None
            for line in proc.stdout:
                self.tk.after(0, lambda l=line: self.log_insert(l))
            code = proc.wait()
            self.tk.after(
                0,
                lambda: self._build_done(code),
            )

        threading.Thread(target=worker, daemon=True).start()

    def _build_done(self, code: int) -> None:
        self.log_insert(f"\n==> exit code {code}\n")
        self.refresh_status()
        if code == 0:
            messagebox.showinfo("Build", "Build finished successfully.")
        else:
            messagebox.showerror("Build", f"Build failed (exit code {code}). See log above.")

    def on_run_game(self) -> None:
        ok, _ = nzp_status()
        if not ok:
            if not messagebox.askyesno(
                "Missing nzp",
                "Game data (nzp/) does not look ready. Run anyway?",
            ):
                return
        if sys.platform == "linux":
            exe = ROOT / "run_game.sh"
            if not exe.is_file():
                messagebox.showerror("Error", f"Missing {exe}")
                return
            subprocess.Popen(["/usr/bin/env", "bash", str(exe)], cwd=str(ROOT))
            self.log_insert("\nLaunched ./run_game.sh\n")
            return
        messagebox.showinfo("Run", "On Windows, use run_game.cmd from the repo root.")

    def on_open_folder(self) -> None:
        path = str(ROOT)
        if sys.platform == "linux":
            subprocess.Popen(["xdg-open", path], cwd=path)
        elif sys.platform == "darwin":
            subprocess.Popen(["open", path])
        else:
            os.startfile(path)  # type: ignore[attr-defined]

    def run(self) -> None:
        self.tk.mainloop()


def main() -> None:
    if not ROOT.joinpath("build.sh").is_file():
        print("Run this from the Operation Deadfall repository (build.sh not found).", file=sys.stderr)
        sys.exit(1)
    InstallApp().run()


if __name__ == "__main__":
    main()
