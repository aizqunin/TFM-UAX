import pandas as pd, numpy as np, json

df = pd.read_parquet(r"C:\Users\cuent\Documents\UAX\TFM\TFM\CodigoGit\data\processed\train.parquet")
dv = pd.read_parquet(r"C:\Users\cuent\Documents\UAX\TFM\TFM\CodigoGit\data\processed\val.parquet")

print("SHAPE:", df.shape, dv.shape)
print("COLS:", list(df.columns))
for c in ["pain","acuity","chiefcomplaint","arrival_transport"]:
    print(f"{c}: dtype={df[c].dtype} nulls={df[c].isna().sum()} unique={df[c].nunique()}")
for t in ["L1","L2","L3"]:
    print(f"{t} prevalencia={df[t].mean()*100:.2f}%")
print("CC unique:", df["chiefcomplaint"].nunique())
print("AT values:", df["arrival_transport"].value_counts().to_dict())

data = np.load(r"C:\Users\cuent\Documents\UAX\TFM\TFM\CodigoGit\data\processed\lstm_sequences_train.npz")
print("X_seq shape:", data["X_seq"].shape)
print("seq_len min/max/mean:", data["seq_len"].min(), data["seq_len"].max(), round(float(data["seq_len"].mean()),2))
vals, counts = np.unique(data["seq_len"], return_counts=True)
for v,c in zip(vals,counts):
    print(f"  seq_len={int(v)}: {c:,} ({c/len(data['seq_len'])*100:.1f}%)")
with open(r"C:\Users\cuent\Documents\UAX\TFM\TFM\CodigoGit\data\processed\lstm_stats.json") as f:
    print("lstm_stats:", json.load(f))
