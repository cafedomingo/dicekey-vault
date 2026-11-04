# Scanner measurements

These are the measurements behind the scanner that `scanning.md` describes: how it compares with read-dicekey, the reasons and numbers behind its constants, and the approaches it tried and dropped. Besides the photo corpus, many of them use the saved frames. These are 1,051 frames from the app on a Mac, in four sessions. They're kept locally, not in the repository.

## Against read-dicekey

`scripts/compare-upstream/compare-upstream.sh` reads the corpus with read-dicekey (commit 0440036, built on OpenCV 4.12.0, the version it pins) as well as with this scanner. It prints tables, including the one below, and one row per photo and size. Both scanners read the same gray bytes. `UpstreamCompareTests` writes them as PGMs, one frame per photo at the four sizes of the corpus tests:

- full size
- the shorter side 1080, the app's scale
- the centered 1080 square the app scans
- the shorter side 810

The corpus tests' rules score the reads. read-dicekey uses a fresh processor for each photo, so it merges nothing. A face counts as read when its `isDefined()` says so. read-dicekey reads nothing from a frame unless its grid fits five rows and columns of underline and overline pairs. OpenCV runs its arm64 code paths here. Other CPUs take other code paths, which may move a face or two.

Faces right/wrong:

|  | full size | shorter side 1080 | centered 1080 square | shorter side 810 |
|---|---|---|---|---|
| well-framed (35 photos, 873 faces): this scanner | 838/0 | 866/0 | 810/0 | 862/0 |
| read-dicekey | 778/0 | 760/0 | 701/0 | 784/1 |
| read-dicekey, keys it calls complete | 20 of 35 | 20 of 35 | 18 of 35 | 21 of 35 |
| other (13 photos, 320 faces): this scanner | 129/0 | 127/0 | 128/0 | 130/0 |
| read-dicekey | 39/0 | 62/0 | 80/0 | 43/1 |
| read-dicekey, keys it calls complete | 0 of 13 | 0 of 13 | 0 of 13 | 1 of 13 |

- **On read-dicekey's own 19 well-framed photos, the two scanners are level.** They read the same at full size, and read-dicekey is two faces behind at each shorter-side size. On the centered square, read-dicekey reads 30 fewer faces than at its other sizes, 25 of them from `S4tI3lZ2t…_well_lit`.
- **The gaps are on the owner's 16 later well-framed photos and on the `other/` photos.** At the app's scale, this scanner reads 391 of the owner's 398 later well-framed faces, and read-dicekey reads 287.
- **Misreads:** this scanner has none at any size. read-dicekey has two, both at the shorter side 810, and it flags both as errors (`errorSize()` 10 and 255).
- **No key:** neither scanner reads a face from any of the nine `nokey-` photos at any size.
- **Video,** 95 frames of 360-pixel luma squares: read-dicekey fits its grid in frame 0 only and never finishes, because it clears its read whenever a frame doesn't fit. This scanner merges the frames. It knows all 25 faces by the end, with no wrong face in any frame.
- **Time per frame,** median, scanning only: this scanner takes 10, 6, 4 and 4 ms at the four sizes, and read-dicekey takes 58, 24, 21 and 15 ms. The times aren't alike. This scanner traces its threshold levels in parallel, and its times come from `swift test -c release`. read-dicekey runs its levels in series, built with `-O3` and timed warm. Neither time includes decoding or resizing the photo.

What the numbers don't say:

- **The tuning used these photos.** Several of the owner's photo names record what this scanner read, with a check by eye where the picture is sharp (`Fixtures/images/README.md`). So if this scanner consistently misread a face, the score would count read-dicekey's correct read as wrong. Neither of read-dicekey's two misreads is on such a photo.
- **"Read" is read-dicekey's own standard,** which counts faces that it flags for the user to confirm. Without them, read-dicekey reads 6 to 14 fewer faces per size from the well-framed photos, and none wrong.

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

Apple's frameworks came first, on the assumption that they would do the job with less code. The first three rows were measured on the 23 photos that the corpus then held, at 1080 pixels on an M2.

| Approach | Result | Why it lost |
|---|---|---|
| Vision `DetectRectanglesRequest` | 0 to 13 rectangles per frame, where a key has 50 bars. Tiled into 36 requests, it still read only 14 faces | It's built for a few prominent quadrilaterals, and it caps its results per request |
| Vision `DetectContoursRequest` | Full reads on about half the photos. Times are mostly 34 to 270 ms, and 10 s on one | One global threshold, where uneven light needs many. Its cost grows faster than the contour count |
| Vision `RecognizeTextRequest` as the reader | 20 to 49% of faces found in a full frame. Given each face's location, 85 to 91% read, with wrong but plausible reads | Built for lines of words. It has no error check, and it needs a detector anyway |
| Vision `DetectRectanglesRequest` and `DetectDocumentSegmentationRequest` for the key's box | Found the box accurately in at most 18 of 103 images |  |
| Template OCR (read-dicekey), replaced by step 5 | As a third vote, it could only veto good reads, because the two codes were right whenever they agreed. As a tie-breaker, it named the right face 14 times and a wrong one 3 times | Each time, it named a face that neither code named. Step 5 only ever settles a face that a code names |
| Canny edge level | 1 more face of 550 (on the corpus of the time) from the well-framed photos at the app's frame size | It cost 2.6 ms and about 120 MB per frame in Core Image, or 9 ms on the CPU |
| Bar ends at a threshold crossing, replaced by the steepest edge (step 3) | 15 fewer faces from the well-framed photos over the four corpus sizes, and 85 fewer from the others | Uneven light along a bar moves where a threshold is crossed |
| Pairing, and the grid through one face (read-dicekey), replaced by the lattice (step 4) | On the saved frames, the lattice reads 1,912 faces and pairing read 478. From one frame each, neither method read a face wrong | The grid through one face needs a face with a full row and column of paired faces. A key with a column cut off by the frame lacks one, and so can a key fully in view. The lattice takes 2.8 ms a scan, against 2.2 ms |
| Reading bars that the frame's edge cuts, at the grid | 2 more faces from the `other/` photos over the four sizes and 3 more from the saved frames | It completed a synthetic key wrong |
| Refusing every line with an end outside the frame, however the scanner found it | 72 fewer faces from the `other/` photos and 81 fewer from the saved frames |  |
| A line read at the grid as a vote on its own | 16 more faces from the `other/` photos over the four sizes, 141 more from the saved frames and 4 more from the well-framed photos | Noise read a wrong underline at a blank place in 8 of 6,000 synthetic frames. One such frame completed a wrong key |
| A brightness gradient along the bar, for dots under sheen | 5 more faces from the well-framed photos over the four sizes and 56 more from the others. It lost all 14 faces of the super-low-res photo at full size and all 15 of the blurry photo in the centered square | Its extra freedom misfits small or blurred dots. Using it only where it fit much better than a flat split gave up the gains |
| Each dot against the ink beside it, for dots under sheen | 63 fewer faces from the well-framed photos over the four sizes |  |
| Perspective grid fitted first | Misread on the dice of a sparse frame | Perspective now only refines a flat grid that at least 16 lines hold |
| Gathering lines anywhere after the perspective refit | Caught dice five rows past the key and lost a well-framed photo | The refit uses a window of one column or row around the lines the flat grid kept |

The project considered OpenCV, AprilTag, zxing-cpp and a Core ML detector, but didn't try them. OpenCV is a large dependency for what steps 2 and 4 do in about 730 lines. The others decode their own tags and symbologies, and a trained model still needs the bars. Finding 50 identical small bars under uneven light is a fiducial-marker problem, like QR codes and AprilTags, and those detectors are hand-written for their markers too.
