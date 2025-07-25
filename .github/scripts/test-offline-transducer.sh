#!/usr/bin/env bash

set -e

log() {
  # This function is from espnet
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}

export GIT_CLONE_PROTECTION_ACTIVE=false

echo "EXE is $EXE"
echo "PATH: $PATH"

which $EXE

log "------------------------------------------------------------"
log "Run NeMo GigaAM Russian models v2"
log "------------------------------------------------------------"
curl -SL -O https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19.tar.bz2
tar xvf sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19.tar.bz2
rm sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19.tar.bz2

$EXE \
  --encoder=./sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19/encoder.int8.onnx \
  --decoder=./sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19/decoder.onnx \
  --joiner=./sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19/joiner.onnx \
  --tokens=./sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19/tokens.txt \
  --model-type=nemo_transducer \
  ./sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19/test_wavs/example.wav

rm -rf sherpa-onnx-nemo-transducer-giga-am-v2-russian-2025-04-19


log "------------------------------------------------------------------------"
log "Run zipformer transducer models (Russian)                              "
log "------------------------------------------------------------------------"
for type in small-zipformer zipformer; do
  url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-$type-ru-2024-09-18.tar.bz2
  name=$(basename $url)
  curl -SL -O $url
  tar xvf $name
  rm $name
  repo=$(basename -s .tar.bz2 $name)
  ls -lh $repo

  log "test $repo"
  test_wavs=(
  0.wav
  1.wav
  )

  for w in ${test_wavs[@]}; do
    time $EXE \
      --tokens=$repo/tokens.txt \
      --encoder=$repo/encoder.onnx \
      --decoder=$repo/decoder.onnx \
      --joiner=$repo/joiner.onnx \
      --debug=1 \
      $repo/test_wavs/$w
  done

  for w in ${test_wavs[@]}; do
    time $EXE \
      --tokens=$repo/tokens.txt \
      --encoder=$repo/encoder.int8.onnx \
      --decoder=$repo/decoder.onnx \
      --joiner=$repo/joiner.int8.onnx \
      --debug=1 \
      $repo/test_wavs/$w
  done
  rm -rf $repo
done

log "------------------------------------------------------------------------"
log "Run zipformer transducer models (Japanese from ReazonSpeech)                              "
log "------------------------------------------------------------------------"
url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-zipformer-ja-reazonspeech-2024-08-01.tar.bz2

name=$(basename $url)
curl -SL -O $url
tar xvf $name
rm $name
repo=$(basename -s .tar.bz2 $name)
ls -lh $repo

cat $repo/test_wavs/*.txt

log "test $repo"
test_wavs=(
1.wav
2.wav
3.wav
4.wav
5.wav
)

for w in ${test_wavs[@]}; do
  time $EXE \
    --tokens=$repo/tokens.txt \
    --encoder=$repo/encoder-epoch-99-avg-1.onnx \
    --decoder=$repo/decoder-epoch-99-avg-1.onnx \
    --joiner=$repo/joiner-epoch-99-avg-1.onnx \
    --debug=1 \
    $repo/test_wavs/$w
done

for w in ${test_wavs[@]}; do
  time $EXE \
    --tokens=$repo/tokens.txt \
    --encoder=$repo/encoder-epoch-99-avg-1.int8.onnx \
    --decoder=$repo/decoder-epoch-99-avg-1.onnx \
    --joiner=$repo/joiner-epoch-99-avg-1.int8.onnx \
    --debug=1 \
    $repo/test_wavs/$w
done
rm -rf $repo

log "------------------------------------------------------------------------"
log "Run Nemo fast conformer hybrid transducer ctc models (transducer branch)"
log "------------------------------------------------------------------------"

url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-fast-conformer-transducer-be-de-en-es-fr-hr-it-pl-ru-uk-20k.tar.bz2
name=$(basename $url)
curl -SL -O $url
tar xvf $name
rm $name
repo=$(basename -s .tar.bz2 $name)
ls -lh $repo

log "test $repo"
test_wavs=(
de-german.wav
es-spanish.wav
hr-croatian.wav
po-polish.wav
uk-ukrainian.wav
en-english.wav
fr-french.wav
it-italian.wav
ru-russian.wav
)
for w in ${test_wavs[@]}; do
  time $EXE \
    --tokens=$repo/tokens.txt \
    --encoder=$repo/encoder.onnx \
    --decoder=$repo/decoder.onnx \
    --joiner=$repo/joiner.onnx \
    --debug=1 \
    $repo/test_wavs/$w
done

rm -rf $repo

url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-fast-conformer-transducer-en-24500.tar.bz2
name=$(basename $url)
curl -SL -O $url
tar xvf $name
rm $name
repo=$(basename -s .tar.bz2 $name)
ls -lh $repo

log "Test $repo"

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder.onnx \
  --decoder=$repo/decoder.onnx \
  --joiner=$repo/joiner.onnx \
  --debug=1 \
  $repo/test_wavs/en-english.wav

rm -rf $repo

url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-fast-conformer-transducer-es-1424.tar.bz2
name=$(basename $url)
curl -SL -O $url
tar xvf $name
rm $name
repo=$(basename -s .tar.bz2 $name)
ls -lh $repo

log "test $repo"

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder.onnx \
  --decoder=$repo/decoder.onnx \
  --joiner=$repo/joiner.onnx \
  --debug=1 \
  $repo/test_wavs/es-spanish.wav

rm -rf $repo

url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-fast-conformer-transducer-en-de-es-fr-14288.tar.bz2
name=$(basename $url)
curl -SL -O $url
tar xvf $name
rm $name
repo=$(basename -s .tar.bz2 $name)
ls -lh $repo

log "Test $repo"

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder.onnx \
  --decoder=$repo/decoder.onnx \
  --joiner=$repo/joiner.onnx \
  --debug=1 \
  $repo/test_wavs/en-english.wav \
  $repo/test_wavs/de-german.wav \
  $repo/test_wavs/fr-french.wav \
  $repo/test_wavs/es-spanish.wav

rm -rf $repo

log "------------------------------------------------------------"
log "Run Conformer transducer (English)"
log "------------------------------------------------------------"

repo_url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-conformer-en-2023-03-18.tar.bz2
curl -SL -O $repo_url
tar xvf sherpa-onnx-conformer-en-2023-03-18.tar.bz2
rm sherpa-onnx-conformer-en-2023-03-18.tar.bz2
log "Start testing ${repo_url}"
repo=sherpa-onnx-conformer-en-2023-03-18
log "Download pretrained model and test-data from $repo_url"

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder-epoch-99-avg-1.onnx \
  --decoder=$repo/decoder-epoch-99-avg-1.onnx \
  --joiner=$repo/joiner-epoch-99-avg-1.onnx \
  --num-threads=2 \
  $repo/test_wavs/0.wav \
  $repo/test_wavs/1.wav \
  $repo/test_wavs/8k.wav

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder-epoch-99-avg-1.int8.onnx \
  --decoder=$repo/decoder-epoch-99-avg-1.onnx \
  --joiner=$repo/joiner-epoch-99-avg-1.int8.onnx \
  --num-threads=2 \
  $repo/test_wavs/0.wav \
  $repo/test_wavs/1.wav \
  $repo/test_wavs/8k.wav

rm -rf $repo

log "------------------------------------------------------------"
log "Run Zipformer transducer (English)"
log "------------------------------------------------------------"

repo_url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-zipformer-en-2023-03-30.tar.bz2
curl -SL -O $repo_url
tar xvf sherpa-onnx-zipformer-en-2023-03-30.tar.bz2
rm sherpa-onnx-zipformer-en-2023-03-30.tar.bz2
repo=sherpa-onnx-zipformer-en-2023-03-30
log "Start testing ${repo_url}"

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder-epoch-99-avg-1.onnx \
  --decoder=$repo/decoder-epoch-99-avg-1.onnx \
  --joiner=$repo/joiner-epoch-99-avg-1.onnx \
  --num-threads=2 \
  $repo/test_wavs/0.wav \
  $repo/test_wavs/1.wav \
  $repo/test_wavs/8k.wav

time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder-epoch-99-avg-1.int8.onnx \
  --decoder=$repo/decoder-epoch-99-avg-1.onnx \
  --joiner=$repo/joiner-epoch-99-avg-1.int8.onnx \
  --num-threads=2 \
  $repo/test_wavs/0.wav \
  $repo/test_wavs/1.wav \
  $repo/test_wavs/8k.wav

lm_repo_url=https://huggingface.co/ezerhouni/icefall-librispeech-rnn-lm
log "Download pre-trained RNN-LM model from ${lm_repo_url}"
GIT_LFS_SKIP_SMUDGE=1 git clone $lm_repo_url
lm_repo=$(basename $lm_repo_url)
pushd $lm_repo
git lfs pull --include "exp/no-state-epoch-99-avg-1.onnx"
popd

bigram_repo_url=https://huggingface.co/vsd-vector/librispeech_bigram_sherpa-onnx-zipformer-large-en-2023-06-26
log "Download bi-gram LM from ${bigram_repo_url}"
GIT_LFS_SKIP_SMUDGE=1 git clone $bigram_repo_url
bigramlm_repo=$(basename $bigram_repo_url)
pushd $bigramlm_repo
git lfs pull --include "2gram.fst"
popd

log "Start testing with LM and bi-gram LODR"
# TODO: find test examples that change with the LODR
time $EXE \
  --tokens=$repo/tokens.txt \
  --encoder=$repo/encoder-epoch-99-avg-1.onnx \
  --decoder=$repo/decoder-epoch-99-avg-1.onnx \
  --joiner=$repo/joiner-epoch-99-avg-1.onnx \
  --num-threads=2 \
  --decoding_method="modified_beam_search" \
  --lm=$lm_repo/exp/no-state-epoch-99-avg-1.onnx \
  --lodr-fst=$bigramlm_repo/2gram.fst \
  --lodr-scale=-0.5  \
  $repo/test_wavs/0.wav \
  $repo/test_wavs/1.wav \
  $repo/test_wavs/8k.wav

rm -rf $repo $lm_repo $bigramlm_repo

log "------------------------------------------------------------"
log "Run Paraformer (Chinese)"
log "------------------------------------------------------------"
# For onnxruntime 1.18.0, sherpa-onnx-paraformer-zh-2023-03-28 throws the following error
# libc++abi: terminating with uncaught exception of type Ort::Exception: Node (Loop_5471)
# Op (Loop) [TypeInferenceError] Graph attribute inferencing failed: Node (Concat_5490)
# Op (Concat) [ShapeInferenceError] All inputs to Concat must have same rank. Input 1 has rank 2 != 1
#
# See https://github.com/microsoft/onnxruntime/issues/8115
# We need to re-export this model using a recent version of onnxruntime and onnx

log "------------------------------------------------------------"
log "Run Paraformer (Chinese) with timestamps"
log "------------------------------------------------------------"

repo_url=https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-paraformer-zh-2023-09-14.tar.bz2
curl -SL -O $repo_url
tar xvf sherpa-onnx-paraformer-zh-2023-09-14.tar.bz2
rm sherpa-onnx-paraformer-zh-2023-09-14.tar.bz2
repo=sherpa-onnx-paraformer-zh-2023-09-14

log "Start testing ${repo_url}"

time $EXE \
  --tokens=$repo/tokens.txt \
  --paraformer=$repo/model.int8.onnx \
  --num-threads=2 \
  --decoding-method=greedy_search \
  $repo/test_wavs/0.wav \
  $repo/test_wavs/1.wav \
  $repo/test_wavs/2.wav \
  $repo/test_wavs/8k.wav

rm -rf $repo
