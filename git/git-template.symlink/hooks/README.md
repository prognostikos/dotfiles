Once again, thanks @tpope!

http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html

The pre-push hook delegates to `git-verify-push-signatures` and rejects pushes
that introduce commits without valid signatures. Run `git-reinit-hooks` to
refresh hooks in existing repositories.
