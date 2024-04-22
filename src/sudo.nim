## Detect if you are running as root, restart self with sudo if needed or setup uid zero when running with the SUID flag set.
##
## - GitHub: https://github.com/FyraLabs/sudo.nim
## - Nimble: https://nimble.directory/pkg/sudo
## - Docs: https://fyralabs.github.io/sudo.nim/
##
## ## Requirements
## - The `sudo` program is required to be installed and setup correctly on the target system.
##
## ## Thanks
## ♥ Idea from https://gitlab.com/dns2utf8/sudo.rs
import sweet, sugar, results, posix, std/[cmdline, os, osproc, strutils]

export results

type RunningAs* = enum
  raRoot, raUser, raSuid

type R = Result[RunningAs, string]


proc sudo_check*(): RunningAs =
  ## Check `posix.getuid()` and `posix.geteuid()` to learn about the process configuration.
  if !geteuid():
    if !getuid(): return raRoot
    return raSuid
  return raUser

proc sudo*(filter: (string, string) -> bool): R =
  ## Escalate program priviledge using `sudo` as needed.
  ## Explicitly exports environment variables for `filter(key, value) == true`.
  ##
  ## **Parameters**
  ## 
  ## - `filter: proc (key, value: string): bool`
  ##   When returns true, the key-value pair environment variable in concern will be propagated.
  ## - `prefixes: openArray[string] = []`
  ##   All envionment variables pairs, with the name of the key that start with any strings in `prefixes`, will be propagated.
  ##
  ## **Return**
  ## 
  ## - if priviledge escalation is unnecessary for the current process: `results.Result[RunningAs, string]`
  ## - if priviledge escalation is performed: does not return and `quit()` with exit code of `sudo`
  ##
  ## **Examples**
  ##
  ## ```nim
  ## import sudo, sugar
  ## discard sudo()
  ## # or…
  ## discard sudo(["QT_"])  # exports envvars that start with QT_
  ## discard sudo((k, _) => k.startsWith("QT_"))  # equivalent to above
  ## ```
  let current = sudo_check()
  case current
  of raRoot: return ok current
  of raSuid:
    let res = setuid(0)
    if res != 0:
      return err "setuid(0) returned " & $res
    return ok current
  of raUser: discard
  let sudo = findExe "sudo"
  if !sudo: return err "sudo not found in cwd and $PATH."
  let params = commandLineParams() # argv excluding executable path
  let cmd = getAppFilename()

  # propagate envvars that satisfies filter()
  let envvars = collect:
    for (k, v) in envPairs():
      if filter(k, v): k&"="&v

  let p = startProcess(sudo, args = envvars+cmd+params, options = {poParentStreams})
  quit p.waitForExit

proc sudo*(prefixes: openArray[string] = []): R =
  ## See documentations for `sudo(filter)`_.
  proc match(k: string, _: string): bool =
    for prefix in prefixes:
      if k.startsWith prefix:
        return true
    return false
  sudo(match)
