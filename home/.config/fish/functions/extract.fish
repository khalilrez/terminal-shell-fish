function extract --description 'Extract any common archive format'
    if test (count $argv) -eq 0
        echo 'usage: extract <archive>...' >&2
        return 1
    end
    for f in $argv
        if not test -f $f
            echo "extract: '$f' is not a file" >&2
            continue
        end
        switch $f
            case '*.tar.gz' '*.tgz'
                tar xzf $f
            case '*.tar.bz2' '*.tbz2' '*.tbz'
                tar xjf $f
            case '*.tar.xz' '*.txz'
                tar xJf $f
            case '*.tar.zst' '*.tzst'
                tar --zstd -xf $f
            case '*.tar'
                tar xf $f
            case '*.gz'
                gunzip -k $f
            case '*.bz2'
                bunzip2 -k $f
            case '*.xz'
                unxz -k $f
            case '*.zst'
                unzstd $f
            case '*.zip' '*.jar'
                unzip $f
            case '*.rar'
                unrar x $f
            case '*.7z'
                7z x $f
            case '*.Z'
                uncompress $f
            case '*'
                echo "extract: don't know how to extract '$f'" >&2
        end
    end
end
