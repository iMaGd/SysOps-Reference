# 📘 Bash Scripting Reference

A practical cheat sheet for advanced Bash usage, globbing, redirection, pipes, environment variables, and configuration.

---

## 🔹 Installation & Updating Bash
- On macOS, install or update Bash via **Homebrew**:
  ```bash
  brew install bash
  ```

---

## 🔹 Globbing & File Matching
- Match multiple file types:
  ```bash
  mv *.(js|json) .
  ```
- Enable recursive globbing (`**`):
  ```bash
  shopt -s globstar
  cp **/*.jpg **/*.mov .
  ```

---

## 🔹 Redirection & File Descriptors

### File Descriptors
- `stdin` → `0`
- `stdout` → `1`
- `stderr` → `2`

### Redirects
- Redirect stdout to file:
  ```bash
  command > out.txt
  ```
- Redirect stderr to file:
  ```bash
  command 2> error.txt
  ```
- Redirect stdout to stderr:
  ```bash
  command 1>&2
  ```
- Redirect stderr to stdout:
  ```bash
  command 2>&1
  ```
- Redirect both to same file:
  ```bash
  command > out.txt 2>&1
  ```
- Redirect to “black hole” (skip):
  ```bash
  command > /dev/null 2>&1
  ```

---

## 🔹 Pipes (`|`)
- Send **stdout of one command** to **stdin of another**:
  ```bash
  ls -l | grep ".txt"
  ```

### `tee` Command
- Write to file **and** keep printing to terminal:
  ```bash
  echo "Hello" | tee file.txt
  ```
- Append mode:
  ```bash
  echo "Hello again" | tee -a file.txt
  ```
- Combine with other commands:
  ```bash
  echo "Hello" | tee file.txt | wc -c
  ```

### Write multiple lines to a file

- `cat` reads from standard input (your keyboard or whatever comes after <<EOF)
- `>` redirects that output into the file `output.txt`, overwriting it. or
- `>>` redirects that output into the file `output.txt`, appending it.

```bash
cat > output.txt <<'EOF'
...
EOF
```

---

## 🔹 `grep` Command
- Search inside files:
  ```bash
  grep 'pattern' file.txt
  ```
- Fixed string match (`-F`):
  ```bash
  grep -F 'text' file.txt
  ```
- With pipes:
  ```bash
  ls | grep -F 'file'
  ```

---

## 🔹 Text Processing Tools
### `tr`
- Translate or delete characters.
  ```bash
  echo "hello" | tr 'a-z' 'A-Z'
  ```

### `cut`
- Extract columns or fields.
  ```bash
  cut -d',' -f2 file.csv
  ```

### `sed`
- Stream editor for text manipulation.
- Replace:
  ```bash
  sed 's/foo/bar/g' file.txt
  ```
- Delete:
  ```bash
  sed '/pattern/d' file.txt
  ```
- Insert:
  ```bash
  sed '1i\New Line' file.txt
  ```

---

## 🔹 Variables & Environment

### Bash Variables
- Defined inside shell session.
- Syntax:
  ```bash
  myvar="hello"
  echo "${myvar}"
  ```
- **No spaces** around `=`.
- Case-sensitive: `myVar` ≠ `myvar`.
- No data types — all values are strings.

### Environment Variables
- Export variable to OS level:
  ```bash
  export VAR="value"
  ```
- Overwrite:
  ```bash
  VAR="new_value"
  ```
- Remove:
  ```bash
  unset VAR
  ```
- List all:
  ```bash
  env
  ```
- Difference:
  - **Bash variables** → local to current session.
  - **Environment variables** → global, inherited by OS processes.
  - Convention: Bash vars = lowercase, ENV vars = UPPERCASE.

---

## 🔹 Executable Bash Scripts & Shebang
- First line defines interpreter:
  ```bash
  #!/bin/bash
  ```
- Better practice (portable):
  ```bash
  #!/usr/bin/env bash
  ```
- Make executable:
  ```bash
  chmod +x script.sh
  ```

---

## 🔹 Bash Startup & Config Files
When storing PATH changes or ENV vars:
- `~/.bash_profile`
- `~/.bash_login`
- `~/.profile`
- `~/.bashrc`

💡 Use `~/.bashrc` for most interactive shell configs.
💡 Add binaries to `PATH` via:
```bash
export PATH="$PATH:/custom/bin"
```

---

## 🔹 File Hierarchy Essentials
- `/bin` → Essential binaries (basic commands, always available).
- `/sbin` → Essential system binaries (root/admin tools).
- `/usr/bin` → Non-essential binaries, available to all users.

---

## 🔹 The `$SHELL` Variable
- Shows user’s default shell:
  ```bash
  echo $SHELL
  ```
- Change default:
  ```bash
  chsh -s /bin/bash
  ```
  - Must exist in `/etc/shells`.
  - Requires re-login to take effect.

---

## 🔹 Aliases
- List all defined aliases:
  ```bash
  alias
  ```
- Define:
  ```bash
  alias ll="ls -la"
  ```
- Remove:
  ```bash
  unalias ll
  ```

---
