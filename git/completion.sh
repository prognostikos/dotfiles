_wt() {
  local state
  local -a local_branches all_branches

  local_branches=(
    ${(f)"$(git for-each-ref \
      --format='%(refname:short)' refs/heads 2>/dev/null)"}
  )

  all_branches=(
    ${(f)"$(git for-each-ref \
      --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null)"}
  )
  all_branches=(${all_branches:#*/HEAD})

  _arguments \
    '(-h --help)'{-h,--help}'[show help]' \
    '1:branch name:->local-branches' \
    '2:base branch:->all-branches'

  case "$state" in
    local-branches)
      _describe 'local branch' local_branches
      ;;
    all-branches)
      _describe 'base branch' all_branches
      ;;
  esac
}

compdef _wt wt
