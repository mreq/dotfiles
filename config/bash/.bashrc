# Source Fedora system-wide bashrc (history, prompt, completion, color, etc.)
[ -f /etc/bashrc ] && . /etc/bashrc

export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
export PATH="$HOME/.local/bin:$PATH"

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

subl() {
	local -a args=()
	for a in "${@:-$(pwd)}"; do
		[[ -e "$a" ]] && args+=("$(realpath "$a")") || args+=("$a")
	done
	"$HOME/.local/share/dotfiles/bin/launch_desktop" apps-sublime_text "${args[@]}"
}
