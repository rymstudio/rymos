# RymOS: mostra fastfetch solo nelle sessioni SSH interattive
case $- in
    *i*)
        if [ -n "$SSH_CONNECTION" ] && [ -t 1 ] && command -v fastfetch >/dev/null 2>&1; then
            fastfetch
        fi
        ;;
esac
