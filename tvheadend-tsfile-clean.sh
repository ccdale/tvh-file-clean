#!/bin/bash
function getPids()
{
    ifn=$1
    bfn=$(basename "$ifn")
    tmpop=${workdir}/${bfn}.ffprobe.op
    ffprobe -i "$ifn" >"$tmpop" 2>&1
    vpid=$(sed -n '/^[ \t]*Stream .* Video: .*$/s/.*\[\(0x[0-9a-f]*\)\].*/\1/p' "$tmpop")
    apid=$(sed -n '/^[ \t]*Stream .* Audio: .*, stereo, .*$/s/.*\[\(0x[0-9a-f]*\)\].*/\1/p' "$tmpop")
    # spid=$(sed -n '/^[ \t]*Stream .* Subtitle: .*$/s/.*\[\(0x[0-9a-f]*\)\].*/\1/p' "$tmpop")
    pids=
    if [ ${#apid} -gt 0 ]; then
        if [ ${#vpid} -gt 0 ]; then
            pids="${vpid},${apid}"
        else
            pids=${apid}
        fi
    fi
    echo $pids
}

function duration()
{
    ifn=$1
    ffprobe "$ifn" 2>&1 |sed -n '/[ \t]*Duration:.*/s/^[ \t]*Duration: \([0-9]\+:[0-9]\+:[0-9]\+\)\.[0-9]*,.*$/\1/p'
}

workingdir=~/.tmpvid
logdir=~/.logs
[[ -d $workingdir ]] || mkdir $workingdir
[[ -d $logdir ]] || mkdir $logdir
workdir=${workingdir}/$$.tmp
mkdir $workdir
infn=$1
cp "$infn" $workdir/
basefn=$(basename "$infn")
desc=$2
chan=$3
sttime=$4
endtime=$5
err=$6
logfn=${logdir}/${basefn}-${chan}-${sttime}-${endtime}.log
echo "$infn" >>"$logfn"
echo "$chan" >>"$logfn"
echo "$sttime - $endtime" >>"$logfn"
echo "$desc" >>"$logfn" >>"$logfn"
echo "error reported: '$err'" >>"$logfn"
if [[ ${#err} -gt 0 && ${err} != "OK" ]]; then
    echo "TVHeadend reports an error in recording" >>"$logfn"
    exit 1
fi
outopts="-out $workdir/"
idpids=$(getPids "$infn")
idopt=
if [[ ${#idpids} -gt 0 ]]; then
    idopt="-id $idpids"
fi
pxlog=${logfn}.px.log
projectx $outopts $idopt "$infn" >"$pxlog" 2>&1
fnbase=${basefn%.*}
m2v=${fnbase}.m2v
echo "m2v: $m2v" >>"$logfn"
mp2=${fnbase}.mp2
echo "mp2: $mp2" >>"$logfn"
op=${fnbase}.mpg
echo "mpg: $op" >>"$logfn"
cd $workdir
if [[ -f "$m2v" && -f "$mp2" ]]; then
    echo "multiplexing $m2v and $mp2 to $op" >>"$logfn"
    mplex -f 9 -o "${op}" "$m2v" "$mp2" >>"$logfn" 2>&1
    if [[ -r "$op" ]]; then
        durmpg=$(duration "$op")
        durifn=$(duration "$infn")
        echo "Cleaning of $infn completed" >>"$logfn"
        echo "Duration input file: $durifn" >>"$logfn"
        echo "Duration output file: $durmpg" >>"$logfn"
        echo "copying cleaned file to tvheadend dir" >>"$logfn"
        cp "$op" "$infn"
        rm -rf $workdir
    else
        echo "Mission output file $op" >>"$logfn"
        exit 1
    fi
else
    echo "cannot read $m2v and/or $mp2" >>"$logfn"
    exit 1
fi
