# sousrir

## Search on untranscribed speech rapidly in R

### Basic usage: gos-kdl Librosa features and default functions

Within the R package, we have supplied features extracted from the gos-kdl QbE-STD dataset ([https://zenodo.org/record/4634878](https://zenodo.org/record/4634878)) extracted using a simple python feature extraction script using the Librosa library (script provided below). You can fetch the full path of these feature files using the `system.file()` function:

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
results_df <- qbe_std(
	queries_loc    = gos_kdl_queries,
	references_loc = gos_kdl_refs
)
```

By default, this call will result in a data frame as the one shown below where for each pair of query and reference there is a score of how likely the query occurs reference (higher is more likely):

| query |        reference      | score |
|-------|-----------------------|-------|
| ED_aapmoal | OV-aapmoal-verschillend-mor-<b>aapmoal</b>-prachteg-van-kleur |   0.2138   |
| ED_aapmoal | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-achter-de-teunbaank        |   0.213   |
|  ED_achter  | OV-aapmoal-verschillend-mor-aapmoal-prachteg-van-kleur |   0.3123   |
|  ED_achter  | RB-de-gruinteboer-staait-mit-n-blaauw-schoet-veur-<b>achter</b>-de-teunbaank        |   1.33123 |

### Advanced usage: Bring your own features and functions (BYOFs)

This package is *very* un-opinionated with regards to what features you should use, how they should be stored, what subsets of the data should be searched, in what form the results should be returned (CSV, JSON, etc.). Nearly every stage of the search process is customizable through supplying your own function for that stage.

#### Custom fetcher functions

For example, the `qbe_std()` function takes `names_fetcher` and `features_fetcher` arguments:

```r
qbe_std(
	query_loc        = gos_kdl_queries,
	references_loc   = gos_kdl_refs,
	names_fetcher    = fetch_npz_names,
	features_fetcher = fetch_npz_item
)
```

Thus if your feature store is an Amazon S3 bucket or a NoSQL database or whatever else, you may supply your own fetcher functions which return the identifiers of the queries and references you want to perform a QbE-STD search on (`names_fetcher`) and a way to fetch the feature matrices associated with an identifier (`features_fetcher`), the default functions for which are:

```r
fetch_npz_names <- function(npz_file) {
  np <- reticulate::import("numpy")

  np$load(npz_file)$files
}

fetch_npz_item <- function(npz_file, item_name) {
  np <- reticulate::import("numpy")

  np$load(npz_file)$f[[item_name]]
}
```

In this way `query_loc` and `references_loc` do not have to be paths to npz files. They should be locations of whatever you decide is appropriate for your set up (e.g. S3 bucket, database table, etc.). Your fetcher functions should deal with authentication or any other pre-processing that needs to happen.

#### Custom search manifest

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

If you want to subset the queries or references on which the search is performed, you can provide your own function that creates the search manifest. For example, if you have a database of true negatives, you may want to filter out those pairs to skip searching on them or if you are developing your search pipeline, you may want to select just the first 10 pairs.

#### Feature extraction script

```
# Download an unzip gos-kdl QbE-STD dataset
wget https://zenodo.org/record/4634878/files/gos-kdl.zip
unzip gos-kdl.zip

# Copy/create make_librosa_npz.py script in gos-kdl directory
# cp /path/to/make_librosa_npz.py gos-kdl

# Change directory and run python script to create queries.npz and references.npz
cd gos-kdl
python make_librosa_npz.py
```

- `make_librosa_npz.py`

	```python
	import librosa
	import numpy as np
	import os
	
	for wav_dir in ['queries', 'references']:
		wav_files   = os.listdir(wav_dir)
		wav_data    = [ librosa.load(os.path.join(wav_dir, wf), sr=16000)[0] for wf in wav_files ]
		mfcc_data   = [ librosa.feature.mfcc(y=y, sr=16000).T for wd in wav_data ]
		
		output_dict = { 
			os.path.splitext(wav_name)[0]: mfcc_data[index] for
			index, wav_name in enumerate(wav_files)
		}
		
		np.savez_compressed(wav_dir + '.npz', **output_dict)
	```
	
- `queries.npz`:

	```
	{
		'ED_aapmoal': array([[...]]),
		...
		'ED_moane': array([[...]])
	}  
	```


### Bring your own features and functions (BYOFs)

#### Example with gos-kdl QbE-STD dataset and librosa



### Advanced usage (bring your own functions)