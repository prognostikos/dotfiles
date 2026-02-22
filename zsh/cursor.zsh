# Reset cursor to terminal default after each command.
# Fixes applications like nvim that set a steady cursor on exit,
# overriding the terminal's configured blinking cursor.
_reset_cursor() { printf '\e[0 q' }
precmd_functions+=(_reset_cursor)
