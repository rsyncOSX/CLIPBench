# AI Model Licences and Downloads

RawCull can use optional, converted Core AI model bundles. These models are
separate downloads and are not part of the RawCull application. Each model
remains governed by its upstream licence even when RawCull downloads, verifies,
installs, or runs it.

This page explains the terms presented when model downloads become available
in **RawCull > Settings > AI**. It is not a substitute for the complete licence
included with each downloaded model.

## Before a Model Download

Before a download begins, RawCull shows:

- the model name, purpose, publisher, exact version, and immutable upstream
  revision;
- that RawCull is the converter and distributor of the Core AI bundle, but not
  the creator of the upstream model;
- the applicable licence name and licence version or date;
- links to the complete licence, upstream source, model card, and conversion
  information;
- the download size, installed size, macOS and hardware requirements, and
  expected SHA-256 checksum; and
- whether explicit licence acceptance is required.

For a model that requires acceptance, the checkbox is not selected in advance.
Selecting **Accept and Download** confirms that the user has read and agrees to
the displayed licence. RawCull stores a local record of the model, revision,
licence version, licence-text checksum, acceptance date, and RawCull version.
A changed licence must be presented and accepted before a corresponding model
update is downloaded.

Downloading contacts the server that hosts the model, so that server receives
the connection information needed to deliver the file. RawCull does not send
photographs, prompts, embeddings, masks, or inference results as part of a
model download. After installation, model inference runs locally on the Mac.

## What Each Model Archive Must Contain

Every model archive distributed by RawCull must include:

- a complete, verbatim copy of every applicable model licence and copyright
  notice;
- the upstream model repository, immutable revision, original filenames, and
  source-file checksums;
- the RawCull bundle version, conversion tool and version, conversion settings,
  and converted-asset checksum;
- the model card, or an offline notice accompanied by a link to the model card;
  and
- the `metadata.json`, Core AI asset, tokenizer resources, and other files
  required by the model.

The licence copy inside the archive remains available with the installed model
and in RawCull's **Third-Party Models** information. A website link alone does
not replace the licence copy that must accompany a redistributed model.

## Supported Model Licences

### OpenAI CLIP ViT-B/32

- Upstream checkpoint:
  [OpenAI CLIP ViT-B/32](https://huggingface.co/openai/clip-vit-base-patch32)
- Upstream source:
  [OpenAI CLIP](https://github.com/openai/CLIP)
- Source-project licence:
  [MIT License](https://github.com/openai/CLIP/blob/main/LICENSE)
- Model card:
  [CLIP model details, intended uses, and limitations](https://huggingface.co/openai/clip-vit-base-patch32)

The OpenAI CLIP source project is published under the MIT License, which
requires the copyright and permission notice to remain with copies or
substantial portions. The Hugging Face checkpoint page does not currently
include a separate licence file for the weights. RawCull must therefore verify
and record that the licence covers the exact checkpoint and revision before
offering its converted bundle for download.

The model card describes deployed use as outside the model's original intended
scope and recommends careful, task-specific evaluation. RawCull uses CLIP only
as a local review and search aid; it does not treat similarity as certainty or
make the photographer's decisions.

### OpenCLIP ViT-B/32 DataComp

- Upstream checkpoint and model card:
  [OpenCLIP ViT-B/32 DataComp `s34B-b86K`](https://huggingface.co/laion/CLIP-ViT-B-32-256x256-DataComp-s34B-b86K)
- OpenCLIP source:
  [mlfoundations/open_clip](https://github.com/mlfoundations/open_clip)
- OpenCLIP licence:
  [MIT License](https://github.com/mlfoundations/open_clip/blob/main/LICENSE)

The checkpoint page identifies this model as MIT-licensed. A RawCull conversion
must retain the complete applicable MIT copyright and permission notice. Before
release, RawCull must pin the exact checkpoint revision and include the licence
text and provenance in the downloadable archive.

### Meta SAM 3

- Official model and model card:
  [Meta SAM 3](https://huggingface.co/facebook/sam3)
- Complete licence:
  [SAM License](https://huggingface.co/facebook/sam3/blob/main/LICENSE)
- Source repository:
  [facebookresearch/sam3](https://github.com/facebookresearch/sam3)

SAM 3 is not MIT-licensed. Meta's SAM License applies to the model weights,
software, documentation, modifications, and derivative works. A converted Core
AI model is distributed subject to that licence.

Important SAM License conditions include:

- SAM materials and derivatives may be provided to another person only under
  the SAM License, and a complete copy of that agreement must accompany them;
- use must comply with applicable laws, privacy and data-protection law, export
  restrictions, sanctions, and the licence's prohibited-use provisions;
- use must not involve or encourage reverse engineering, decompilation, or
  discovery of underlying model components;
- specified military, warfare, nuclear, espionage, gun, illegal-weapon, and
  other trade-controlled uses are prohibited;
- published research results produced using SAM materials must acknowledge
  their use;
- the licence contains warranty disclaimers, liability limitations,
  indemnification, intellectual-property provisions, termination conditions,
  and a requirement to delete and stop using the materials following
  termination; and
- Meta may amend the licence as described in the agreement.

The official files are gated by Hugging Face and may require sign-in, contact
information, and acceptance of Meta's terms. RawCull must not bypass that gate
or publish an ungated converted SAM 3 download until the proposed
redistribution and acceptance flow has been confirmed as compatible with the
SAM License and the official access conditions.

When an approved RawCull download is available, the action is labelled
**Accept and Download** and requires agreement to the complete SAM License.
The downloaded archive also contains an exact copy of that licence.

## RawCull's MIT Licence

RawCull itself is open-source software distributed under the
[MIT License](https://github.com/rsyncOSX/RawCull/blob/main/Licence.MD).
Copyright (c) 2026, Thomas Evensen.

The RawCull MIT License permits use, copying, modification, distribution,
sublicensing, and sale of the software, provided that its copyright and
permission notice are retained. That licence covers the RawCull software. It
does not replace, extend, or relicense the optional third-party AI models.

The warranty and liability provision in RawCull's MIT License states:

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

Accordingly, to the extent permitted by applicable law, RawCull's author and
copyright holders do not provide a warranty and are not liable for faults,
errors, incorrect AI results, data loss, or other claims or damages arising
from use of the software. AI results are review aids and must be checked by the
photographer.

The MIT disclaimer does not remove rights or remedies that cannot legally be
excluded under applicable consumer or other mandatory law. The separately
downloaded models also carry their own warranty disclaimers and liability
terms, as stated in their licences.

## Updates and Removal

RawCull enables a model only after validating its manifest and expected
checksum. Validation checks integrity and compatibility; it does not guarantee
that the model is accurate, suitable for a particular photograph, or free of
bias or errors.

Users can continue using RawCull without downloading any AI model. Removing a
downloaded model disables the features that require it but leaves RawCull's
non-AI culling features available.

Model availability, versions, licence revisions, and checksums are recorded in
the [RawCull release notes](/blog/releases/). Review those notes and the
licence presented by RawCull before every new model or model update.
