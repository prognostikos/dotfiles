Once again, thanks @tpope!

http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html

The post-operation hooks submit ctags jobs to a private tmux server. This keeps
Git operations asynchronous and lets tmux reap the jobs, including in a
container whose PID 1 does not reap orphan processes. If tmux is unavailable,
the dispatcher runs ctags synchronously.

The pre-push hook delegates to `git-verify-push-signatures` and rejects pushes
that introduce commits without valid signatures. Run `git-reinit-hooks` to
refresh hooks in existing repositories.
