## # sudo
##
## Detect if you are running as root, restart self with sudo if needed or setup uid zero when running with the SUID flag set.
##
## ## Requirements
## - The `sudo` program is required to be installed and setup correctly on the target system.
#
# ♥ Idea from https://gitlab.com/dns2utf8/sudo.rs
import sweet, sugar, results, posix, std/[cmdline, os, osproc, strutils]

export results

type RunningAs* = enum
  raRoot, raUser, raSuid

type R = Result[RunningAs, string]


proc sudo_check*(): RunningAs =
  ## Check `getuid()` and `geteuid()` to learn about the configuration this program is running under.
  if !geteuid():
    if !getuid(): return raRoot
    return raSuid
  return raUser

proc sudo*(prefixes: openArray[string] = []): R =
  ## Escalate program priviledge using `sudo` as needed.
  ## Explicitly exports environment variables that start with strings listed in param `prefixes`.
  ##
  ## ## Examples
  ##
  ## ```nim
  ## import sudo
  ## discard sudo()
  ## # or…
  ## discard sudo(["QT_"])  # this exports environment variables that start with QT_
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

  # propagate envvars with prefixes
  let envvars = collect:
    for (k, v) in envPairs():
      var done = false
      for prefix in prefixes:
        if done: break
        if k.startsWith(prefix):
          done = true
          k&"="&v

  let p = startProcess(sudo, args=envvars+cmd+params, options={poParentStreams})
  quit p.waitForExit
