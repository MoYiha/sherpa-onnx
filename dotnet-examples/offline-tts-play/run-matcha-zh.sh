#!/usr/bin/env bash
set -ex

# please visit
# https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/matcha.html#matcha-icefall-zh-baker-chinese-1-female-speaker
# to download more models
if [ ! -f ./matcha-icefall-zh-baker/model-steps-3.onnx ]; then
  curl -SL -O https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/matcha-icefall-zh-baker.tar.bz2
  tar xvf matcha-icefall-zh-baker.tar.bz2
  rm matcha-icefall-zh-baker.tar.bz2
fi

if [ ! -f ./hifigan_v2.onnx ]; then
  curl -SL -O https://github.com/k2-fsa/sherpa-onnx/releases/download/vocoder-models/hifigan_v2.onnx
fi


dotnet run \
  --matcha-acoustic-model=./matcha-icefall-zh-baker/model-steps-3.onnx \
  --matcha-vocoder=./hifigan_v2.onnx \
  --lexicon=./matcha-icefall-zh-baker/lexicon.txt \
  --tokens=./matcha-icefall-zh-baker/tokens.txt \
  --dict-dir=./matcha-icefall-zh-baker/dict \
  --tts-rule-fsts=./matcha-icefall-zh-baker/phone.fst,./matcha-icefall-zh-baker/date.fst,./matcha-icefall-zh-baker/number.fst \
  --debug=1 \
  --output-filename=./matcha-zh.wav \
  --text="某某银行的副行长和一些行政领导表示，他们去过长江和长白山; 经济不断增长。2024年12月31号，拨打110或者18920240511。123456块钱。"