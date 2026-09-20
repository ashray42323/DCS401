import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score

os.makedirs("figures", exist_ok=True)

df = pd.read_csv("data/Mall_Customers.csv")
print("shape:", df.shape)

X = df[["Annual Income (k$)", "Spending Score (1-100)"]]
X_scaled = StandardScaler().fit_transform(X)

# elbow method to pick a good k
scores = []
for k in range(1, 11):
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    km.fit(X_scaled)
    scores.append(km.inertia_)

plt.plot(range(1, 11), scores, marker="o")
plt.title("Elbow Method")
plt.xlabel("number of clusters (k)")
plt.ylabel("inertia")
plt.tight_layout()
plt.savefig("figures/elbow.png", dpi=150)
plt.close()

# looks like 5 is a good choice
km = KMeans(n_clusters=5, random_state=42, n_init=10)
df["Cluster"] = km.fit_predict(X_scaled)
print("silhouette score:", round(silhouette_score(X_scaled, df["Cluster"]), 3))

# plot the clusters
for c in range(5):
    part = df[df["Cluster"] == c]
    plt.scatter(part["Annual Income (k$)"], part["Spending Score (1-100)"], label="Cluster " + str(c))
plt.title("Customer Segments")
plt.xlabel("Annual Income (k$)")
plt.ylabel("Spending Score (1-100)")
plt.legend()
plt.tight_layout()
plt.savefig("figures/clusters.png", dpi=150)
plt.close()

# average of each group
print("\nsegment averages:")
print(df.groupby("Cluster")[["Annual Income (k$)", "Spending Score (1-100)", "Age"]].mean().round(1))

print("\ndone, plots saved in figures folder")
