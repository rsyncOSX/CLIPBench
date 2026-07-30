# CLIPBench Test

CLIPBench is an experimental command-line tool for testing local semantic
search across photo collections. This test package includes the `clipbench`
binary and a converted CLIP DataComp model.

## Requirements

- Apple silicon Mac
- macOS 27 or later
- A copied or backed-up photo directory for testing

CLIPBench supports JPEG, PNG, HEIC/HEIF, TIFF, and Sony ARW files. ARW files
are indexed using their embedded JPEG previews.

## Quick start

Open Terminal, change to this directory, and run:

```sh
./clipbench inspect-model --model ./CLIP-DataComp
./clipbench index "/path/to/photos" --model ./CLIP-DataComp
./clipbench search "/path/to/photos" "bird in flight" \
  --model ./CLIP-DataComp --top 10
```

The first model use may take additional time while macOS prepares and
specializes the model.

CLIPBench does not modify the source photos. It creates a hidden `.clipbench`
directory inside the directory being indexed and stores the generated search
index there. Removing that hidden directory removes the generated index.

All model inference runs locally on the Mac. CLIPBench does not upload photos,
search prompts, or embeddings.

## Experimental software

This package is for testing. Semantic-search results are relative similarity
scores, not statements of fact, and may be inaccurate, incomplete, biased, or
unexpected. Do not rely on the results for safety-critical, legal, medical,
employment, identity, surveillance, or other high-impact decisions.

Use CLIPBench only on content you are authorized to process. Test first with
copies or backed-up photo directories.

## Licences and no warranty

CLIPBench, PhotoAIKit, and RawParserKit are distributed under the MIT Licence.
Those licence texts are included in this package. The converted model and its
OpenCLIP source are identified as MIT-licensed by the upstream model
repository. The tokenizer files originate from OpenAI CLIP and are accompanied
by the OpenAI MIT Licence.

Apple `coreai-models`, used in the conversion/runtime toolchain, is distributed
under the BSD 3-Clause Licence. Its required notice is also included.

See `MODEL-INFORMATION.md`, `PROVENANCE.json`, and the
`THIRD-PARTY-NOTICES` directory for details and source links.

CLIPBench is provided **"AS IS"**, without warranty of any kind, express or
implied. To the fullest extent stated in the included MIT Licence, the
copyright holders and contributors are not liable for claims, damages, or
other liability arising from the software or its use. This includes faults,
errors, incorrect search results, data loss, and incompatibility. This summary
does not replace the complete licence terms.

## Integrity check

Before running the package:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

The distributor must regenerate `SHA256SUMS.txt` and recreate the ZIP after
code-signing `clipbench`, because signing changes the executable.

