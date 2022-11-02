#!/bin/bash
rm -fr *.log
exte=".mp4|.mkv"

modoDeUso() { 
    echo "Modo de uso: $0 [OPCIÓN]  ";
    echo "OPCIONES:" ;
    echo " Por defecto extrae idiomas eng,esp,spa";
    echo "-l, especifica un idioma, ej1: eng , ej2: spa" 
    echo "-a, extrae todos los idomas";
    echo "-h, help"
}
 
extract(){
    local LANG=${1} ;
    fil=$(ls | grep -E $exte | wc -l)
    if [ $fil -eq 0 ] ; then
        echo "[-] No existen archivos de videos con extenciones $exte ";
        exit 1
    fi
    for i in $(ls | grep -E $exte ); do
        ffmpeg -i $i -report 2>/dev/null 
        logs=$(cat *.log | wc -l)
        extensions=$(echo $exte| sed 's/|/\\|/g')
        if [ $logs -gt 0 ]; then
            # posicion del primer subtitlo
            posicion=$(cat *.log | grep Subtitle | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | head -n 1 )
            # lista de subtitulos en idioma eng
            pos=$(cat *.log | grep Subtitle | grep $LANG | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | xargs )
            if [ ${#pos} -gt 0 ]; then
                n=0
                for j in $pos; do
                    sub=$(echo $i | sed "s/$extensions/.$LANG.$n.srt/g" )
                    echo $sub
                    resta=$(($j-$posicion))
                    ffmpeg -i $i -c copy -map 0:s:$resta "$sub" -y 2>/dev/null
                    n=$(($n+1))
                done;
            else
                echo "[-] No se encontraron subtitulos en idioma $LANG";
            fi
        fi
    done;
    
    rm -fr *.log  
}

extractEngSpa(){
    fil=$(ls | grep -E $exte | wc -l)
    if [ $fil -eq 0 ] ; then
        echo "[-] No existen archivos de videos con extenciones $exte ";
        exit 1
    fi
    for i in $(ls | grep -E $exte ); do
        ffmpeg -i $i -report 2>/dev/null 
        logs=$(cat *.log | wc -l)
        extensions=$(echo $exte| sed 's/|/\\|/g')
        if [ $logs -gt 0 ]; then
            # posicion del primer subtitlo
            posicion=$(cat *.log | grep Subtitle | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | head -n 1 )
            # lista de subtitulos en idioma eng
            pos=$(cat *.log | grep Subtitle | grep eng | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | xargs )
            if [ ${#pos} -gt 0 ]; then
                n=0
                for j in $pos; do
                    sub=$(echo $i | sed "s/$extensions/.en.$n.srt/g" )
                    echo $sub
                    resta=$(($j-$posicion))
                    ffmpeg -i $i -c copy -map 0:s:$resta "$sub" -y 2>/dev/null
                    n=$(($n+1))
                done;
            else
                echo "[-] No se encontraron subtitulos en ingles.";
            fi
            # subtitulos en español: spa , esp
            pos=$(cat *.log | grep Subtitle | grep -E "esp|spa" | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | xargs )
            if [  ${#pos} -gt 0 ]; then
                n=0
                for j in $pos; do
                    sub=$(echo $i | sed "s/$extensions/.es.$n.srt/g" )
                    echo $sub
                    resta=$(($j-$posicion))
                    ffmpeg -i $i -c copy -map 0:s:$resta "$sub" -y 2>/dev/null
                    n=$(($n+1))
                done;
            else 
                echo "[-] No se encontraron subtitulos en español.";
            fi
            
        fi
    done;
    
    rm -fr *.log  
}
 
extractAll(){
    fil=$(ls | grep -E $exte | wc -l)
    if [ $fil -eq 0 ] ; then
        echo "[-] No existen archivos de videos con extenciones $exte ";
        exit 1
    fi
    for i in $(ls | grep -E $exte ); do
        ffmpeg -i $i -report 2>/dev/null 
        logs=$(cat *.log | wc -l)
        extensions=$(echo $exte| sed 's/|/\\|/g')
        if [ $logs -gt 0 ]; then
            # posicion del primer subtitlo
            posicion=$(cat *.log | grep Subtitle | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | head -n 1 )
            # extraer listado de posiciones de subtitulos : 23-esp  
            # pos=$(cat *.log | grep Subtitle | grep -oP ':\d{1,2}' | awk '{print $2}' FS=':' | xargs )
            pos=$(cat *.log | grep Subtitle | grep -oP ':\d{1,2}\(.*?\)' | sed 's/://g' | sed 's/)//g' | sed 's/(/-/g' )
            # si longitud > 0 tiene caracteres
            if [ ${#pos} -gt 0 ]; then
                n=0
                for j in $pos; do
                    p=$(echo $j | awk '{print $1}' FS='-')
                    name=$(echo $j | awk '{print $2}' FS='-')
                    sub=$(echo $i | sed "s/$extensions/.$name.$n.srt/g" )
                    echo $sub
                    resta=$(($p-$posicion))
                    ffmpeg -i $i -c copy -map 0:s:$resta "$sub" -y 2>/dev/null
                    n=$(($n+1))
                done;
            else
                echo "[-] No se encontraron subtitulos en idioma $LANG";
            fi
        fi
    done;
    
    rm -fr *.log  
}

while getopts "l:ah" o; do
    case "${o}" in
        l)
            l=${OPTARG}
            echo "Extraer subtitulos en idioma ${l}";
            extract ${l}
            exit 0;
        ;;
        a)
            echo "Extraer todos los subtitulos";
            extractAll
            exit 0;
        ;;
        h|*)
            modoDeUso
            exit 0;
        ;;
         
    esac
done
shift $((OPTIND-1))
 
extractEngSpa

exit 0



