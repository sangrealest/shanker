shopt -s histappend
export HISTCONTROL=ignoreboth
PROMPT_COMMAND='history -a'

alias grep='grep --color=auto -i'
alias vi='vim'
alias ll='ls  --color=auto -hltr'
alias la='ls --color=auto -alhtr'
alias dstat='dstat -lpcmdnsy --top-io --top-mem --top-cpu --top-bio'
alias ..='cd ..'
alias gadd='git add'
alias gco='git commit -m'
alias pce='puppet cert'
alias mpstat='mpstat -P All'
alias pmem='ps -eo "%C:%p:%z:%a"|sort -k3 -nr|head'
alias pcpu='ps -eo "%C:%p:%z:%a"|sort -nr|head'

alias yin='sudo yum -y install'
alias yse='sudo yum search'
alias ain='sudo apt-get install -y'
alias ase='sudo apt-cache search'

alias sls='screen -ls'
alias sdr='screen -dr'

export PATH=$PATH:/sbin:.

export PS1="\[\e[00;32m\][\[\e[0m\]\[\e[00;31m\]\u\[\e[0m\]\[\e[00;32m\]@\[\e[0m\]\[\e[00;33m\]\H:\[\e[0m\]\[\e[00;35m\]\w\[\e[0m\]\[\e[00;32m\]\A]\[\e[0m\]\[\e[00;36m\]\\$\[\e[0m\]"

function mkcd(){
    mkdir -p $1
        cd $1
}
#service $1 restart
function rs(){
    service $1 restart
}
#rm -rf
function fuck(){
    rm -rf $1
}
#chkconfig
function chon(){
    chkconfig $1 on
}
