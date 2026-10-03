"""Spike counts of human hippocampal neurons during the encoding period of a Sternberg task.

Source (real data, not simulated):
    Kyzar M, Kaminski J, Brzezicka A, Reed CM, Chung JM, Mamelak AN, Rutishauser U.
    Dataset of human-single neuron activity during a Sternberg working memory task.
    Scientific Data 11, 89 (2024). https://doi.org/10.1038/s41597-024-02943-8
    Data: DANDI Archive, dandiset 000469 (NWB format), license CC-BY-4.0.
    Code that accompanies the release: github.com/rutishauserlab/workingmem-release-NWB

What this script does: it streams the 21 Sternberg sessions (`ses-2` files, session
description starting with "SB") from DANDI without downloading the waveforms, keeps the
neurons recorded in the hippocampus, and counts, for every neuron and every trial, the
spikes between the onset of the first image and the end of the last image shown in that trial
(the "encoding window"; the window therefore lasts longer when more images are shown and
differs between patients because the protocol's image duration differs).

Output: project/AnalysisData/WorkingMemory_Hippocampus_Encoding.csv, one row per neuron and
trial: patient, unit (neuron number within the patient), hemisphere, trial, load (images
shown, 1 to 3), window_s (length of the encoding window in seconds), spikes.

Requirements: python with h5py, remfile, requests, numpy, pandas.
Run from the project root: python functions/extract_workingmem_counts.py
"""
import os

import h5py
import numpy as np
import pandas as pd
import remfile
import requests

DANDISET = "000469"
API = "https://api.dandiarchive.org/api"
OUT = os.path.join("project", "AnalysisData", "WorkingMemory_Hippocampus_Encoding.csv")


def list_assets():
    assets, url = [], f"{API}/dandisets/{DANDISET}/versions/draft/assets/?page_size=100&order=path"
    while url:
        page = requests.get(url, timeout=60).json()
        assets += [(a["path"], a["asset_id"]) for a in page["results"]]
        url = page.get("next")
    return assets


def flat_table(group):
    """Read the one-dimensional, non-ragged columns of an NWB DynamicTable into a DataFrame."""
    cols = {}
    for key in group:
        node = group[key]
        if isinstance(node, h5py.Dataset) and node.ndim == 1 and not key.endswith("_index"):
            values = node[:]
            if values.dtype.kind in ("S", "O"):
                values = np.array([v.decode() if isinstance(v, bytes) else v for v in values])
            cols[key] = values
    return pd.DataFrame(cols)


def session_counts(asset_id):
    f = h5py.File(remfile.File(f"{API}/assets/{asset_id}/download/"), "r")
    if not f["session_description"][()].decode().startswith("SB"):  # SB = Sternberg, SC = screening
        return None
    patient = int(f["general/subject/subject_id"][()].decode())
    trials = flat_table(f["intervals/trials"])
    location = np.array(flat_table(f["general/extracellular_ephys/electrodes"])["location"])
    units = f["units"]
    ends = units["spike_times_index"][:]
    starts = np.r_[0, ends[:-1]]
    spike_times = units["spike_times"][:]
    unit_location = location[units["electrodes"][:]]

    load = trials["loads"].values.astype(int)
    last_end = np.select(
        [load == 1, load == 2],
        [trials["timestamps_Encoding1_end"], trials["timestamps_Encoding2_end"]],
        default=trials["timestamps_Encoding3_end"],
    )
    window_start = trials["timestamps_Encoding1"].values
    window_s = last_end - window_start

    rows = []
    for k in range(len(ends)):
        if "hippocampus" not in unit_location[k]:
            continue
        spikes = spike_times[starts[k]:ends[k]]
        counts = np.searchsorted(spikes, last_end) - np.searchsorted(spikes, window_start)
        rows.append(pd.DataFrame({
            "patient": patient,
            "unit": k + 1,
            "hemisphere": unit_location[k].split("_")[-1],
            "trial": trials["id"].values + 1,
            "load": load,
            "window_s": np.round(window_s, 3),
            "spikes": counts,
        }))
    return pd.concat(rows, ignore_index=True) if rows else None


if __name__ == "__main__":
    pieces = []
    for path, asset_id in list_assets():
        out = session_counts(asset_id)
        if out is not None:
            print(path, out.groupby("unit").ngroups, "hippocampal neurons")
            pieces.append(out)
    data = pd.concat(pieces, ignore_index=True)
    assert (data["window_s"] > 0).all()
    data.to_csv(OUT, index=False)
    print(len(data), "rows,", data.groupby(["patient", "unit"]).ngroups, "neurons,", data["patient"].nunique(), "patients ->", OUT)
