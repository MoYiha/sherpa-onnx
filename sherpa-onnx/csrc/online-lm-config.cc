// sherpa-onnx/csrc/online-lm-config.cc
//
// Copyright (c)  2023  Xiaomi Corporation

#include "sherpa-onnx/csrc/online-lm-config.h"

#include <string>

#include "sherpa-onnx/csrc/file-utils.h"
#include "sherpa-onnx/csrc/macros.h"

namespace sherpa_onnx {

void OnlineLMConfig::Register(ParseOptions *po) {
  po->Register("lm", &model, "Path to LM model.");
  po->Register("lm-scale", &scale, "LM scale.");
  po->Register("lm-num-threads", &lm_num_threads,
               "Number of threads to run the neural network of LM model");
  po->Register("lm-provider", &lm_provider,
               "Specify a provider to LM model use: cpu, cuda, coreml");
  po->Register("lm-shallow-fusion", &shallow_fusion,
               "Boolean whether to use shallow fusion or rescore.");
  po->Register("lodr-fst", &lodr_fst, "Path to LODR FST model.");
  po->Register("lodr-scale", &lodr_scale, "LODR scale.");
  po->Register("lodr-backoff-id", &lodr_backoff_id,
               "ID of the backoff in the LODR FST. -1 means autodetect");
}

bool OnlineLMConfig::Validate() const {
  if (!FileExists(model)) {
    SHERPA_ONNX_LOGE("'%s' does not exist", model.c_str());
    return false;
  }

  if (!lodr_fst.empty() && !FileExists(lodr_fst)) {
    SHERPA_ONNX_LOGE("'%s' does not exist", lodr_fst.c_str());
    return false;
  }

  return true;
}

std::string OnlineLMConfig::ToString() const {
  std::ostringstream os;

  os << "OnlineLMConfig(";
  os << "model=\"" << model << "\", ";
  os << "scale=" << scale << ", ";
  os << "lodr_scale=" << lodr_scale << ", ";
  os << "lodr_fst=\"" << lodr_fst << "\", ";
  os << "lodr_backoff_id=" << lodr_backoff_id << ", ";
  os << "shallow_fusion=" << (shallow_fusion ? "True" : "False") << ")";

  return os.str();
}

}  // namespace sherpa_onnx
