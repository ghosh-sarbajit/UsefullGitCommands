# dir aliases
alias up1='cd ../'
alias up2='cd ../../'
alias up3='cd ../../../'
alias up4='cd ../../../../'
alias up5='cd ../../../../../'
alias up6='cd ../../../../../../'
alias up7='cd ../../../../../../../'
alias up8='cd ../../../../../../../../'
alias up9='cd ../../../../../../../../../'
alias up10='cd ../../../../../../../../../../'

up () {
    local d=""
    local limit=$1
    for ((i=1; i<=limit; i++)); do
        d+="../"
    done
    cd "$d" || return
}

tarxz() {
    # No arguments
    if [ "$#" -eq 0 ]; then
        echo "Usage:"
        echo "  tarxz <file_or_folder>                  -> creates name.tar.xz"
        echo "  tarxz <archive.tar.xz> <items...>       -> custom archive name"
        return 1
    fi

    local archive
    local items=()

    # ---- Case 1: single argument ----
    if [ "$#" -eq 1 ]; then
        local item="$1"

        if [ ! -e "$item" ]; then
            echo "Error: '$item' does not exist"
            return 1
        fi

        # remove trailing slash if directory
        item="${item%/}"
        archive="$(basename "$item").tar.xz"
        items=("$item")

    # ---- Case 2: ≥2 arguments ----
    else
        archive="$1"
        shift
        items=("$@")

        # Validate all items exist
        for item in "${items[@]}"; do
            if [ ! -e "$item" ]; then
                echo "Error: '$item' does not exist"
                return 1
            fi
        done
    fi

    # Detect CPU cores
    local cores
    cores=$(nproc)
    echo "Detected CPU cores: $cores"

    # Compress
    echo "Compressing into: $archive"
    tar -cvf "$archive" -I "xz -9e -T${cores}" "${items[@]}"

    if [ $? -eq 0 ]; then
        echo "Successfully created: $archive"
    else
        echo "Compression failed"
        return 1
    fi
}

alias gis='git status'
alias gip='git pull'
alias gic='git clone'

alias tma='tmux attach -t'
alias tml='tmux ls'
alias tmn='tmux new -s'
alias bc='bc -l'

# HIST CONTROL
HISTSIZE=1000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="ls:pwd:history:exit:clear"

__my_prompt_cmd() { history -a; history -c; history -r; }
PROMPT_COMMAND="__my_prompt_cmd"

shopt -s histappend # Ubuntu 22.04 already had this

gpu-check() {
    for pid in $(nvidia-smi --query-compute-apps=pid --format=csv,noheader,nounits | sort -u); do
        echo "======================================================"
        echo "PID: $pid"

        USER=$(ps -o user= -p "$pid" 2>/dev/null || echo "N/A")
        PARENT_PID=$(ps -o ppid= -p "$pid" 2>/dev/null || echo "N/A")

        echo "User    : $USER"
        echo "Parent  : $PARENT_PID"

        if [ -r "/proc/$pid/cmdline" ]; then
            CMDLINE=$(tr '\0' ' ' < "/proc/$pid/cmdline" | sed 's/ $//')
            echo "Cmdline : $CMDLINE"
        else
            echo "Cmdline : (unavailable)"
        fi

        echo "CWD     : $(readlink -f /proc/$pid/cwd 2>/dev/null || echo 'N/A')"

        echo "GPU Usage:"
        nvidia-smi --query-compute-apps=gpu_uuid,pid,used_gpu_memory \
                   --format=csv,noheader,nounits |
        while IFS=',' read -r uuid p mem; do
            p=$(echo "$p" | xargs)
            if [ "$p" = "$pid" ]; then
                gpu=$(nvidia-smi --query-gpu=index,uuid \
                                 --format=csv,noheader,nounits |
                      awk -F',' -v uuid="$(echo "$uuid" | xargs)" \
                      '$2 ~ uuid {print $1}')
                echo "  GPU $gpu : ${mem} MiB"
            fi
        done

        echo
    done
}
