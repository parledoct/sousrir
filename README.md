# sousrir: Search on untranscribed speech rapidly in R

**This package is under active development, with many things bound to change — do not use in production!**

Pronounced 'soo-rear' (like the French *sourire* 'to smile').

### 1. Installation

#### 1.1 R package 

Use the `install_github` function from the remotes package to install this development version of the R package. We will put a version on CRAN once the package functionality has stabilised.

```r
# Install remotes package if you don't have it
# install.packages("remotes")

remotes::install_github("parledoct/sousrir")
```

#### 1.2 Miniconda

If you do not already have an installation of Miniconda for use by R, use the `install_miniconda()` function from the reticulate package (which is a dependency of sousrir, and will be automatically installed). The reticulate package lets you use Python functions and data structures in R, and needs access to its own (clean) installation of Miniconda.

```r
reticulate::install_miniconda()
```

### 2. Basic usage: gos-kdl Librosa features and default functions

Within the R package, we have supplied features extracted from the gos-kdl QbE-STD dataset ([https://zenodo.org/record/4634878](https://zenodo.org/record/4634878)) extracted using a simple python feature extraction script using the Librosa library (script provided below, in 3.1). You can fetch the full path of these feature files on your local system using the `system.file()` function:

```r
gos_kdl_queries <- system.file("extdata", "gos-kdl_queries.npz", package="sousrir")
gos_kdl_refs    <- system.file("extdata", "gos-kdl_references.npz", package="sousrir")
```

Each npz file (zipped archive of NumPy arrays) contains a dictionary where each named item is a 2-dimensional NumPy array where the rows are time frames and columns are feature components (we thus expect the number of columns to be the same across all items and files).

As shown below, for `gos-kdl_queries.npz`, the data associated with item named `ED_aapmoal` is extracted from the file `queries/ED_aapmoal.wav` (see Zenodo repository for original wav files) and is a NumPy array with 37 rows (time frames) and 20 columns (MFCC components; 20 is the default for [librosa.feature.mfcc](https://librosa.org/doc/main/generated/librosa.feature.mfcc.html)). `ED_achter ` has the same number of columns, but fewer rows (22) from being a shorter .wav file.

```
{
    'ED_aapmoal': array([[16.485865, -11.592721, -14.900574, 20.032818, ... ]]), # (37, 20)
    ...
    'ED_achter': array([[11.749482, -9.294043, -6.118123, -7.8093295, ...]])     # (22, 20)
}  
```

To perform the query-by-example spoken term detection search with all default options, use the `qbe_std()` function, supplying the locations of the queries and references.


```r
library(sousrir)

results_df <- qbe_std(
    queries_loc    = gos_kdl_queries,
    references_loc = gos_kdl_refs
)
```

By default, this call will result in a data frame as the one shown below where for each pair of query and reference there is a score of how likely the query occurs reference (higher is more likely), and the start and end indices of the region in the reference that was most similar to the query:

| query |        reference      | score | match_start | match_end |
|-------|-----------------------|-------|------|------| 
| ED_aapmoal | OV-<b>aapmoal</b>-verschillend-mor-aapmoal-prachteg-van-kleur |   0.7463992   | 5 | 32 |
| ED_aapmoal | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-achter-de-teunbaank        |   0.6739399   | 60 | 93 |
|  ED_achter  | OV-aapmoal-verschillend-mor-aapmoal-prachteg-van-kleur |   0.7209738   | 108 | 130 |
|  ED_achter  | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-<b>achter</b>-de-teunbaank        |   0.7986339 | 92 | 108 |

We intentionally do not convert the time frame indices into seconds by default, because the conversion process is highly dependent on how you originally extracted the features. In the case of gos-kdl, we extracted features from audio sampled at 16 kHz (16000 samples per second) using the default parameters of the [librosa.feature.mfcc](https://librosa.org/doc/main/generated/librosa.feature.mfcc.html) function (`hop_length`: 512 samples per step). If you know these parameters, you can use the `samp2sec_libmfcc` function to convert the time frame indices into seconds:

```r
results_df$match_start <- samp2sec_libmfcc(results_df$match_start, 16000, 512)
results_df$match_end   <- samp2sec_libmfcc(results_df$match_end, 16000, 512)
```

| query |        reference      | score | match_start | match_end |
|-------|-----------------------|-------|------|------| 
| ED_aapmoal | OV-<b>aapmoal</b>-verschillend-mor-aapmoal-prachteg-van-kleur |   0.7463992   | 0.160 | 1.024 |
| ED_aapmoal | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-achter-de-teunbaank        |   0.6739399   | 1.920 | 2.976 |
|  ED_achter  | OV-aapmoal-verschillend-mor-aapmoal-prachteg-van-kleur |   0.7209738   | 3.456 | 4.16 |
|  ED_achter  | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-<b>achter</b>-de-teunbaank        |   0.7986339 | 2.944 | 3.456 |

### 3. Advanced usage: Bring your own features and functions (BYOFs)

This package is *very un-opinionated* with regards to what features you should use, how they should be stored, what subsets of the data should be searched, in what form the results should be returned (CSV, JSON, etc.). Nearly every stage of the search process is customizable through supplying your own function for that stage.

#### 3.1 Use your own features

The script used to extract features from the gos-kdl dataset ([https://zenodo.org/record/4634878](https://zenodo.org/record/4634878)) using [librosa.feature.mfcc](https://librosa.org/doc/main/generated/librosa.feature.mfcc.html) is:

```python
import librosa
import numpy as np
import os
	
for wav_dir in ['queries', 'references']:
	# List wav files in 'queries' or 'references' directory
	wav_files   = os.listdir(wav_dir)
	
	# Read in wav files
	wav_data    = [ librosa.load(os.path.join(wav_dir, wf), sr=16000)[0] for wf in wav_files ]
	
	# Extract MFCC features
	mfcc_data   = [ librosa.feature.mfcc(y=y, sr=16000).T for wd in wav_data ]
	
	output_dict = { 
		# For key name get filename without extension, e.g. 'ED_aapmoal.wav' => 'ED_aapmoal'
		# For the value fetch the relevant value from the mfcc_data list given the index 
		
		os.path.splitext(wav_name)[0]: mfcc_data[index] for
		index, wav_name in enumerate(wav_files)
	}
	
	# Supply dict as arguments to np.savez_compressed function
	np.savez_compressed(wav_dir + '.npz', **output_dict)
```

You may extract features using whatever library you want (e.g. Kaldi, wav2vec 2.0, etc.). If you would like to use the default feature reader functions, you can save your features as npz file by adapting the `output_dict` as appropriate. 

#### 3.2 Use your own fetcher functions

You do not need to supply your features in the `npz` format or even have the `npz` files structured in the way assumed above. If you already have a feature store, you can supply your own `names_fetcher` and `features_fetcher` arguments to the `qbe_std` function instead of the defaults:

```r
qbe_std(
	query_loc        = gos_kdl_queries,
	references_loc   = gos_kdl_refs,
	names_fetcher    = fetch_npz_names,
	features_fetcher = fetch_npz_item
)

# Default implementations, for reference:
fetch_npz_names <- function(npz_file) {
  np <- reticulate::import("numpy")
 
  # Returns a character vector of all key names in the npz archive
  np$load(npz_file)$files
}

fetch_npz_item <- function(npz_file, item_name) {
  np <- reticulate::import("numpy")

  # Returns the feature matrix from an npz archive, given the key name
  np$load(npz_file)$f[[item_name]]
}
```

Thus if your feature store is an Amazon S3 bucket or a NoSQL database or whatever else, you may supply your own fetcher functions which return the identifiers of the queries and references you want to perform the QbE-STD search on (`names_fetcher`) and a way to fetch the feature matrix associated with a location and identifier (`features_fetcher`).

In this way `query_loc` and `references_loc` do not have to be paths to npz files. They should be locations of whatever you decide is appropriate for your set up (e.g. S3 bucket, database table, etc.). Your fetcher functions should deal with authentication or any other pre-processing that needs to happen.

#### 3.3 Build your own search manifest

The QbE-STD search process operates on pairs of queries and references. Using the default function `create_allcomb_df` will create a data frame with two columns (`query` and `reference`) with all possible combinations of the supplied query and reference names:

```r
create_allcomb_df <- function(query_files, reference_files) {

  expand.grid(
    query     = query_files,
    reference = reference_files,
    stringsAsFactors = FALSE
  )

}
```

If you want to subset the queries or references on which the search is performed, you can provide your own function that creates the search manifest. For example, if you have a database of true negatives or already completed searches, you may want to filter out those pairs to skip searching on them.

#### 3.4 Use your own post-processor

By default, we return a data frame of the form: 

| query |        reference      | score | match_start | match_end |
|-------|-----------------------|-------|------|------| 
| ED_aapmoal | OV-<b>aapmoal</b>-verschillend-mor-aapmoal-prachteg-van-kleur |   0.7463992   | 5 | 32 |
| ED_aapmoal | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-achter-de-teunbaank        |   0.6739399   | 60 | 93 |
|  ED_achter  | OV-aapmoal-verschillend-mor-aapmoal-prachteg-van-kleur |   0.7209738   | 108 | 130 |
|  ED_achter  | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-<b>achter</b>-de-teunbaank        |   0.7986339 | 92 | 108 |

Using the `create_qbestd_df` post-processor function:

```r
create_qbestd_df <- function(search_mf, search_results) {

  # Combine search manifest and search results
  return_df <- cbind(
    search_mf,
    search_results,
    stringsAsFactors = FALSE
  )

  # Sort by query (ascending) and then score (descending)
  return_df <- return_df[order(return_df$query, -return_df$score), ]
  
  # Reset row names after sort
  rownames(return_df) <- 1:nrow(return_df)

  return_df

}
```

If you want to generate a form of the results that works most readily with whatever down stream processes you have, you can adjust this form by supplying your own post-processor function.

#### 3.5 Use your own DTW search functions

The primary reason this package is written in R instead of Python is because we rely heavily on the IncDTW R package to shortlist the best location(s) to do full DTW comparisons on, which are computationally expensive over a large search manifest.

While the IncDTW R package helps with shortlisting, its other DTW-related functionality is relatively limited compared to the `dtw` package (which has both R and Python versions). For example, as of April 2021, the `IncDTW` package does not implement the `SymmetricP1` step function ([Sakoe & Chiba, 1978](https://doi.org/10.1109/TASSP.1978.1163055)). So we shortlist the top match using the `rundtw` function from the IncDTW package and then calculate a score for that top match using the `dtw` function from the dtw package.

##### 3.5.2 Use your own shortlisting function

The default function returns the starting index of the top match. Since this is a kNN search, you can search for more than one (i.e. set `k = 3`, for example). If you do, you should write your own DTW scoring and post-processing functions, as the default functions will not handle more than 1 match.

```r
sousrir_1nndtw <- function(query_feats, ref_feats) {

  IncDTW::rundtw(
    Q = query_feats,
    C = ref_feats,
    dist_method = 'norm2',
    step_pattern = 'symmetric2',
    scale = '01',
    ws = 5,
    lower_bound = TRUE,
    k = 1
  )$knn_indices[1]

}
```

##### 3.5.1 Use your own scoring function

In brief, the default `sousrir_ssdtw` function takes a starting index provided by `sousrir_1nndtw` and performs a DTW-based comparison on between the query and a subsequence of the reference, and returns a similarity score. The main adjustable parameters related to this comparison are:

- `min_match_ratio`: Minimum match length as ratio of query (default: 0.5 = half the query size)
- `max_match_ratio`: Maximum match length as ratio of query (default: 2.0 = twice the query size)
- `distance_func`: Function to compute distances between query and reference (default: `dist_stdeuc`, Standardised Euclidean distance)
- `distnorm_func` Function to normalise computed distances (default: `norm_rf2014`; using procedure from [Rodriguez-Fuentes et al., 2014](https://doi.org/10.1109/ICASSP.2014.6855122))

Of course, you're always welcome to write your own scoring function. For the full implementation of the `sousrir_ssdtw` function, see the `R/dtw_helpers.R` file in this repository.

#### 3.6 Extras: plot distance matrix and DTW alignment

If you want to plot QbE-STD results and you have the tidyverse set of packages installed (e.g. dplyr, tidyr, ggplot2, stringr, etc.), you can load a helper function included in the sousrir package:

```r
# Load plot_qbe_std function

source(system.file("extras", "plot_qbe_std.R", package="sousrir"))
```

This function is not included as the regular set of functions because of it depends on many tidyverse packages to do various wrangling and plotting operations. I assume if you're interested in this level of detail, you are an experienced R developer who does have these packages. But the plotting functionality is not needed for headless deployment, so I have not listed these big packages (e.g. dplyr) as dependencies for sousrir.

```r
query_feats <- fetch_npz_item(gos_kdl_queries, "ED_achter")
ref_feats   <- fetch_npz_item(gos_kdl_refs, "RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-achter-de-teunbaank")

plot_qbe_std(query_feats, ref_feats)
```

![](https://user-images.githubusercontent.com/9938298/114621706-e3a60080-9c61-11eb-9a8e-9a6001c2b856.png)