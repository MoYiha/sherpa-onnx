package main

import (
	"bytes"
	"encoding/binary"
	"log"
	"os"
	"strings"

	sherpa "github.com/k2-fsa/sherpa-onnx-go/sherpa_onnx"
	flag "github.com/spf13/pflag"
	"github.com/youpy/go-wav"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	config := sherpa.OfflineRecognizerConfig{}

	flag.IntVar(&config.FeatConfig.SampleRate, "sample-rate", 16000, "Sample rate of the data used to train the model")
	flag.IntVar(&config.FeatConfig.FeatureDim, "feat-dim", 80, "Dimension of the features used to train the model")

	flag.StringVar(&config.ModelConfig.Transducer.Encoder, "encoder", "", "Path to the transducer encoder model")
	flag.StringVar(&config.ModelConfig.Transducer.Decoder, "decoder", "", "Path to the transducer decoder model")
	flag.StringVar(&config.ModelConfig.Transducer.Joiner, "joiner", "", "Path to the joiner model")

	flag.StringVar(&config.ModelConfig.Paraformer.Model, "paraformer", "", "Path to the paraformer model")

	flag.StringVar(&config.ModelConfig.NemoCTC.Model, "nemo-ctc", "", "Path to the NeMo CTC model")

	flag.StringVar(&config.ModelConfig.ZipformerCtc.Model, "zipformer-ctc", "", "Path to the Zipformer CTC model")

	flag.StringVar(&config.ModelConfig.Dolphin.Model, "dolphin-model", "", "Path to the Dolphin CTC model")

	flag.StringVar(&config.ModelConfig.FireRedAsr.Encoder, "fire-red-asr-encoder", "", "Path to the FireRedAsr encoder model")
	flag.StringVar(&config.ModelConfig.FireRedAsr.Decoder, "fire-red-asr-decoder", "", "Path to the FireRedAsr decoder model")

	flag.StringVar(&config.ModelConfig.Whisper.Encoder, "whisper-encoder", "", "Path to the whisper encoder model")
	flag.StringVar(&config.ModelConfig.Whisper.Decoder, "whisper-decoder", "", "Path to the whisper decoder model")
	flag.StringVar(&config.ModelConfig.Whisper.Language, "whisper-language", "", "Language of the input wave. You can leave it empty ")
	flag.StringVar(&config.ModelConfig.Whisper.Task, "whisper-task", "transcribe", "transcribe or translate")
	flag.IntVar(&config.ModelConfig.Whisper.TailPaddings, "whisper-tail-paddings", -1, "tail paddings for whisper")

	flag.StringVar(&config.ModelConfig.Moonshine.Preprocessor, "moonshine-preprocessor", "", "Path to the moonshine preprocessor model")
	flag.StringVar(&config.ModelConfig.Moonshine.Encoder, "moonshine-encoder", "", "Path to the moonshine encoder model")
	flag.StringVar(&config.ModelConfig.Moonshine.UncachedDecoder, "moonshine-uncached-decoder", "", "Path to the moonshine uncached decoder model")
	flag.StringVar(&config.ModelConfig.Moonshine.CachedDecoder, "moonshine-cached-decoder", "", "Path to the moonshine cached decoder model")

	flag.StringVar(&config.ModelConfig.Tdnn.Model, "tdnn-model", "", "Path to the tdnn model")

	flag.StringVar(&config.ModelConfig.SenseVoice.Model, "sense-voice-model", "", "Path to the SenseVoice model")
	flag.StringVar(&config.ModelConfig.SenseVoice.Language, "sense-voice-language", "", "If not empty, specify the Language for the input wave")
	flag.IntVar(&config.ModelConfig.SenseVoice.UseInverseTextNormalization, "sense-voice-use-itn", 1, " 1 to use inverse text normalization")

	flag.StringVar(&config.ModelConfig.Tokens, "tokens", "", "Path to the tokens file")
	flag.IntVar(&config.ModelConfig.NumThreads, "num-threads", 1, "Number of threads for computing")
	flag.IntVar(&config.ModelConfig.Debug, "debug", 0, "Whether to show debug message")
	flag.StringVar(&config.ModelConfig.ModelType, "model-type", "", "Optional. Used for loading the model in a faster way")
	flag.StringVar(&config.ModelConfig.Provider, "provider", "cpu", "Provider to use")
	flag.StringVar(&config.ModelConfig.ModelingUnit, "modeling-unit", "cjkchar", "cjkchar, bpe, cjkchar+bpe, or leave it to empty")
	flag.StringVar(&config.ModelConfig.BpeVocab, "bpe-vocab", "", "")
	flag.StringVar(&config.ModelConfig.TeleSpeechCtc, "telespeech-ctc", "", "Used for TeleSpeechCtc model")
	flag.StringVar(&config.LmConfig.Model, "lm-model", "", "Optional. Path to the LM model")
	flag.Float32Var(&config.LmConfig.Scale, "lm-scale", 1.0, "Optional. Scale for the LM model")

	flag.StringVar(&config.DecodingMethod, "decoding-method", "greedy_search", "Decoding method. Possible values: greedy_search, modified_beam_search")
	flag.IntVar(&config.MaxActivePaths, "max-active-paths", 4, "Used only when --decoding-method is modified_beam_search")
	flag.StringVar(&config.RuleFsts, "rule-fsts", "", "If not empty, path to rule fst for inverse text normalization")
	flag.StringVar(&config.RuleFars, "rule-fars", "", "If not empty, path to rule fst archives for inverse text normalization")

	flag.StringVar(&config.Hr.DictDir, "hr-dict-dir", "", "If not empty, path to the jieba dict dir for homonphone replacer")
	flag.StringVar(&config.Hr.Lexicon, "hr-lexicon", "", "If not empty, path to the lexicon.txt for homonphone replacer")
	flag.StringVar(&config.Hr.RuleFsts, "hr-rule-fsts", "", "If not empty, path to the replace.fst for homonphone replacer")

	flag.Parse()

	if len(flag.Args()) != 1 {
		log.Fatalf("Please provide one wave file")
	}

	log.Println("Reading", flag.Arg(0))

	samples, sampleRate := readWave(flag.Arg(0))

	log.Println("Initializing recognizer (may take several seconds)")
	recognizer := sherpa.NewOfflineRecognizer(&config)
	log.Println("Recognizer created!")
	defer sherpa.DeleteOfflineRecognizer(recognizer)

	log.Println("Start decoding!")
	stream := sherpa.NewOfflineStream(recognizer)
	defer sherpa.DeleteOfflineStream(stream)

	stream.AcceptWaveform(sampleRate, samples)

	recognizer.Decode(stream)
	log.Println("Decoding done!")
	result := stream.GetResult()

	log.Println("Text: " + strings.ToLower(result.Text))
	log.Println("Emotion: " + result.Emotion)
	log.Println("Lang: " + result.Lang)
	log.Println("Event: " + result.Event)
	log.Printf("Timestamp: %v\n", result.Timestamps)
	log.Printf("Tokens: %v\n", result.Tokens)
	log.Printf("Wave duration: %v seconds", float32(len(samples))/float32(sampleRate))
}

func readWave(filename string) (samples []float32, sampleRate int) {
	file, _ := os.Open(filename)
	defer file.Close()

	reader := wav.NewReader(file)
	format, err := reader.Format()
	if err != nil {
		log.Fatalf("Failed to read wave format")
	}

	if format.AudioFormat != 1 {
		log.Fatalf("Support only PCM format. Given: %v\n", format.AudioFormat)
	}

	if format.NumChannels != 1 {
		log.Fatalf("Support only 1 channel wave file. Given: %v\n", format.NumChannels)
	}

	if format.BitsPerSample != 16 {
		log.Fatalf("Support only 16-bit per sample. Given: %v\n", format.BitsPerSample)
	}

	reader.Duration() // so that it initializes reader.Size

	buf := make([]byte, reader.Size)
	n, err := reader.Read(buf)
	if n != int(reader.Size) {
		log.Fatalf("Failed to read %v bytes. Returned %v bytes\n", reader.Size, n)
	}

	samples = samplesInt16ToFloat(buf)
	sampleRate = int(format.SampleRate)

	return
}

func samplesInt16ToFloat(inSamples []byte) []float32 {
	numSamples := len(inSamples) / 2
	outSamples := make([]float32, numSamples)

	for i := 0; i != numSamples; i++ {
		s := inSamples[i*2 : (i+1)*2]

		var s16 int16
		buf := bytes.NewReader(s)
		err := binary.Read(buf, binary.LittleEndian, &s16)
		if err != nil {
			log.Fatal("Failed to parse 16-bit sample")
		}
		outSamples[i] = float32(s16) / 32768
	}

	return outSamples
}
