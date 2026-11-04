# Scanner measurements

These are the measurements behind the scanner that `scanning.md` describes: how it compares with read-dicekey, the reasons and numbers behind its constants, and the approaches it tried and dropped.

## Against read-dicekey

`scripts/compare-upstream/compare-upstream.sh` reads the corpus with read-dicekey (commit 0440036, built on OpenCV 4.12.0, the version it pins) as well as with this scanner. It prints the tables below, and one row per photo and size. A rerun gives these faces exactly. Times move by a millisecond or so.

Both scanners read the same gray bytes. `UpstreamCompareTests` writes them as PGMs, one frame per photo at the four sizes of the corpus tests:

- full size
- the shorter side 1080, the app's scale
- the centered 1080 square the app scans
- the shorter side 810

The corpus tests' rules score the reads. read-dicekey runs `DiceKeyImageProcessor::processImage`, its grayscale entry, with a fresh processor for each photo, so it merges nothing. A face counts as read when its `isDefined()` says so. That needs an orientation. It also needs a majority of two of underline, overline and its OCR for the letter, and the same for the digit. read-dicekey keeps the faces of a frame only when its grid fits five rows and columns of underline and overline pairs. Otherwise it reads nothing from the frame. OpenCV runs its arm64 code paths here. Other CPUs take other code paths, which may move a face or two.

Faces right/wrong:

|  | full size | shorter side 1080 | centered 1080 square | shorter side 810 |
|---|---|---|---|---|
| well-framed (35 photos, 873 faces): this scanner | 838/0 | 866/0 | 810/0 | 862/0 |
| read-dicekey | 778/0 | 760/0 | 701/0 | 784/1 |
| read-dicekey, keys it calls complete | 20 of 35 | 20 of 35 | 18 of 35 | 21 of 35 |
| other (13 photos, 320 faces): this scanner | 129/0 | 127/0 | 128/0 | 130/0 |
| read-dicekey | 39/0 | 62/0 | 80/0 | 43/1 |
| read-dicekey, keys it calls complete | 0 of 13 | 0 of 13 | 0 of 13 | 1 of 13 |

By whose photo it is, faces right, this scanner / read-dicekey:

|  | full size | shorter side 1080 | centered 1080 square | shorter side 810 |
|---|---|---|---|---|
| read-dicekey's own well-framed (19 photos, 475 faces) | 473 / 473 | 475 / 473 | 467 / 443 | 475 / 473 |
| the owner's well-framed, added later (16 photos, 398 faces) | 365 / 305 | 391 / 287 | 343 / 258 | 387 / 311 |
| read-dicekey's own `other/` (3 photos, 75 faces) | 64 / 19 | 65 / 42 | 66 / 42 | 67 / 43 |
| the owner's `other/` (10 photos, 245 faces) | 65 / 20 | 62 / 20 | 62 / 38 | 63 / 0 |

- **On read-dicekey's own well-framed photos the two are level.** They read the same at full size, and read-dicekey is two faces behind at each shorter-side size. On the centered square, read-dicekey reads 30 fewer faces than at its other sizes. Of these 30, 25 are from `S4tI3lZ2t…_well_lit`, and read-dicekey reads no face from that photo there. This scanner reads 21 faces from it there.
- **The gaps are on the later photos and on read-dicekey's own `other/` ones.**
- **Misreads:** this scanner has none at any size. read-dicekey has two, both at shorter side 810: `G5bS2rW5l…-glare` U4b read as A3l, and `Y6bS2rG4b…` N4b read as N3b. read-dicekey flags both as errors (`errorSize()` 10 and 255), and neither frame passes its complete-key check.
- **No key:** neither scanner reads a face from any of the nine `nokey-` photos at any size. Neither fails on `CausedCrashOn2020-09-18`, read-dicekey's crash-regression input. This scanner reads 20 faces there. Their letters and digits match the printed key by eye. The photo names no key, so the tests don't score them.
- **Video,** 95 frames of 360-pixel luma squares: read-dicekey fits its grid in frame 0 only (18 faces right, none wrong) and never finishes. After every other frame, its read is empty, because it clears the read whenever a frame doesn't fit. This scanner merges the frames. It knows all 25 faces by the end, with no wrong face in any frame. When it reads one frame at a time, it reads faces in 79 frames, and it reads at most 21 faces in one frame.
- **Time per frame,** median, scanning only: this scanner takes 10, 6, 4 and 4 ms at the four sizes. read-dicekey takes 58, 24, 21 and 15 ms.

What the numbers don't say:

- **The tuning used these photos,** which are the test suite of this scanner. Several of the owner's names record what this scanner read, with a check by eye where the picture is sharp (`Fixtures/images/README.md`). So if this scanner consistently misread a face, the score would count read-dicekey's correct read as wrong. Neither of read-dicekey's two misreads is on such a photo.
- **"Read" is read-dicekey's own standard,** which counts faces that it flags (`errorSize()` above 0). Its apps show those faces to the user to confirm. When the count includes only the faces without a flag, read-dicekey reads 6 to 14 fewer per size from the well-framed photos, and none wrong.
- **One frame is a strict test for both scanners,** since both are built for a camera loop. read-dicekey forgets the key on any frame without a grid. This scanner merges frames, and it keeps what it knows through such a frame.
- **The times aren't alike.** This scanner traces its threshold levels in parallel (`DispatchQueue.concurrentPerform` in `Bars.swift`) and was timed inside `swift test -c release`. read-dicekey's levels run in series (OpenCV may parallelize single filters), and it was built with `-O3` and timed warm. The times leave out the time to decode a photo and to resize it.

## Constants and where they come from

`Tuning.swift` holds the scanner's thresholds, one group per step, and its doc comments give the reason for each. The printed geometry they work with is `FaceDimensionsFractional` in `DiceKeySpecification`. These measurements are not in the doc comments:

- **`Tuning.Bars.thresholds`:** read-dicekey's choice, kept after measuring fewer levels. k = 2, 4, ... 10 loses every face of the `fingers` photo in the centered square. Of 200 random sets of 4 or 5 levels, only 3 came within 2 faces of all twelve at every size. So a smaller set would be tuned to these photos.
- **`Tuning.Bars.minimumRegionPixels`:** drops specks before the scanner fits rectangles. A bar is far larger at any usable distance.
- **`Tuning.Bars.proportionSlack`:** the printed geometry, with slack for blur and perspective.
- **`Tuning.Bars` area run:** there are 50 bars of one size. 35 leaves room for missed and extra bars.
- **`Tuning.Slots.tolerance`:** a quarter step is unambiguous, because slots are a whole step apart. The fit also uses it to gather the faces on the grid.
- **`Tuning.Slots.minimumLineLength`:** at 0.92, R4 still read as R5. Also at 0.92, 6 of 22,950 edge-cut synthetic frames and 4 of 3,900 covered synthetic frames read a face wrong. At 0.95, none did. The rule reads 2 fewer faces from the well-framed photos over the four sizes. It reads 1 more from the `other/` photos and 2 more from the saved frames.
- **`Tuning.Grid.sameDieDistance`:** a die's two lines put its middle in one place, within 0.1 of a face in 99 cases of 100. The middle of the next die is 1.3 to 1.9 faces away (well-framed photos, app's scale).
- **`Tuning.Grid.refits`:** two refits read the same faces as three or four over the corpus and the saved frames. One refit read 2 fewer from the well-framed photos (one at full size, one at three quarters of the app's scale) and 1 fewer from the saved frames.
- **`Tuning.Grid.minimumLines`:** pinning needs lines in at least seven slots anyway. Minimums of 4 and 6 read the same faces over the corpus and the saved frames.
- **`Tuning.Grid.minimumLinesForPerspective`:** perspective only refines a flat grid that many lines hold, since it misread when fitted to sparse dice. Without it, the well-framed photos read 34 fewer faces at the app's scale.
- **`Tuning.Grid.maximumStrayLines`:** 2 is one die's two lines: a die beside the key, or a line read on something else.
- **`Tuning.Grid.minimumSlotsOppositeStrays`:** two stray dice fill two slots. So a column of the key that shows one die would otherwise be dropped in their place, and the scanner would read the key a column off. This minimum costs no face over the corpus and the saved frames. A minimum of 4 read 1 fewer from the `other/` photos, and a minimum of 5 also read 16 fewer from the saved frames. When the scanner required the minimum at any span, it refused a well-framed photo at three quarters of the app's scale. In that photo, single stray lines lie ten rows apart.
- **`Tuning.Grid.minimumShareOnKey`:** scattered or jumbled dice put 31 to 41% of their lines on the best grid. A key puts at least 69%.
- **`Tuning.Grid.minimumSlotsOnEachEdge`:** a die past the key's edge fills one slot. Without this minimum, one stray line there pinned the grid of a saved frame a column off.
- **`Tuning.Grid.maximumFaceSideDeviation`:** a grid stretched by a steep tilt measured 0.80 off. Grids that fit measured at most 0.22 over the corpus and 0.40 over the saved frames. It costs no face.
- **`Tuning.Merge.minimumFacesInCommon`:** 5 is too many to match by chance. Frames of a key in view share far more.
- **`MinNumberOfBlackDotsInUndoverline`, `MinNumberOfWhiteDotsInUndoverline`** (`DiceKeySpecification`): every code has at least 4 of each.
- **`Tuning.Lines.minimumDotGap`:** drops 1.6% of the lines that read right and 28% of those that read wrong.
- **`Tuning.Lines.endSearch`:** with read-dicekey's ends, lines that read correctly were 0.93 to 1.03 of their rectangle's length. The first dot starts 5.6% in.
- **`Tuning.Text.gridWidth` and `band`:** 48 samples across a face is one per pixel of the drawn faces. The band clears both bars, and it reaches their inner edges at the largest shift. At this size, the best face was the right one for all 3,630 dice whose lines were found and agree. Samples that averaged 2x2 or 4x4 pixels read no more faces.
- **`Tuning.Text.maximumShift`:** 3 samples, about 6% of a face, cover the error in a center that the scanner infers from one line.
- **`Tuning.Text.maximumSizeVariance`:** dice that the text settles on the corpus are predicted at a quarter of one die's variance (median 0.24), and never above 0.63 of it. Three agreeing dice in a corner would give 81 for the far corner.
- **`Tuning.Text.minimumScore`, `minimumLeadOverOtherFaces`, `minimumLeadOverOtherTurns`:** faces whose lines agree score above 0.80, lead the next face by 0.024 and lead the other turns by 0.139. This holds in 99 cases of 100 (never under 0.75, 0.004 and 0.10).

## Why it works this way: alternatives measured

Apple's frameworks came first. The assumption was that they would do the job with less code. The first three rows were measured on the 23 photos that the corpus then held, at 1080 pixels on an M2:

| Approach | Result | Why it lost |
|---|---|---|
| Vision `DetectRectanglesRequest` | 0 to 13 rectangles per frame. Even a clean synthetic image of 50 bars gives 8 to 12 at real sizes | Built for a few prominent quadrilaterals, and it caps its results per request. Tiling the frame into 36 requests found more rectangles but still read only 14 faces |
| Vision `DetectContoursRequest` | Full reads on about half the photos. Times are mostly 34 to 270 ms, and 10 s on one | One global threshold, where uneven light needs many. Its cost grows faster than the contour count (at 512 pixels, 430 contours took 23 ms and 2,456 took 3.2 s). Dividing the image by its own blur first fixed much of the lighting but not the speed |
| Vision `RecognizeTextRequest` as the reader | 20 to 49% of faces found in a full frame. Given each face's location, 85 to 91% read, with wrong but plausible reads | Built for lines of words, not isolated rotated pairs of characters. It has no error check, it needs a detector anyway, and the fast level only reads upright text |
| Vision `DetectRectanglesRequest` and `DetectDocumentSegmentationRequest` for the key's box | Found the box accurately in at most 18 of 103 images, as they were or inverted |  |
| Template OCR (read-dicekey), replaced by step 5 | As a third vote beside the two codes, it could only veto good reads, because the two codes were right whenever they agreed. As a tie-breaker where the codes disagreed, a port named the right face 14 times and a wrong one 3 times (photos at 1080) | Each time, it named a face that neither code named. Step 5 matches the whole face against faces drawn from the font, and only ever settles a face that a code names |
| Canny edge level, dropped | 1 more face of 550 (on the corpus of the time) from the well-framed photos at the app's frame size | It cost 2.6 ms and about 120 MB per frame in Core Image, or 9 ms on the CPU |
| Bar ends at a threshold crossing, replaced by the steepest edge (step 3) | 15 fewer faces from the well-framed photos over the four corpus sizes, and 85 fewer from the others | Uneven light along a bar moves where a threshold is crossed |
| Pairing, and the grid through one face (read-dicekey), replaced by the lattice (step 4) | Pairing lost nothing over 1,051 frames saved from the app on a Mac (four sessions, kept locally, not in the repository): true pairs missed by at most 0.18 of a face. The grid through one face lost frames. On the saved frames the lattice reads 1,912 faces and pairing read 478. The key of one session was complete at frame 46 instead of 105. From one frame each, neither method read a face wrong | The grid through one face needed one face with a full row and column of paired faces. A key with its left column cut off by the frame lacks it, and so does a key fully in view with 19 paired faces but no complete column. The cost: a scan takes 2.8 ms on average over the photos and frames, against 2.2 ms |
| A brightness gradient along the bar, for dots under sheen | 5 more faces from the well-framed photos over the four sizes and 56 more from the others, but it lost all 14 of the super-low-res photo at full size and all 15 of the blurry photo in the centered square | Its extra freedom misfits small or blurred dots that a flat split reads. Using it only where it fits much better than a flat split gave up the gains |
| Each dot against the ink beside it, for dots under sheen | 63 fewer faces from the well-framed photos over the four sizes | Meant to cancel sheen, since the ink beside a dot carries the same sheen |
| Perspective grid fitted first | Misread on the dice of a sparse frame | Perspective now only refines a flat grid that at least 16 lines hold |
| Gathering lines anywhere after the perspective refit | Caught dice five rows past the key and lost a well-framed photo | The refit uses a window of one column or row around the lines the flat grid kept |

Corpus faces read, lattice against pairing (both counts are from before the external-camera frames of `D32T52S20…` joined the corpus):

- Well-framed photos at the app's scale, three quarters of it, full size and the centered square: 794, 791, 766 and 737 against 795, 791, 769 and 717.
- The others: 110, 113, 109 and 110 against 91, 94, 90 and 92.

The project considered OpenCV, AprilTag, zxing-cpp and a Core ML detector, but didn't try them. OpenCV is a large dependency for what steps 2 and 4 do in about 730 lines. The decoders of the others are for their own tags and symbologies. A trained model needs a pipeline to maintain, and it doesn't remove the need for the bars.

The pattern: Vision's requests are built for a few salient objects per image or for natural text. Apple ships no fast way to find many small blobs. The task is to find 50 identical small bars under uneven light and to decode their dots. This is a fiducial-marker problem, in the family of QR codes and AprilTags. Those detectors are hand-written for their markers too.
