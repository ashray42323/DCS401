import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix

os.makedirs("figures", exist_ok=True)

df = pd.read_csv("data/Telco_Churn.csv")
print("shape:", df.shape)

# TotalCharges has some blank values, so fix them and drop empty rows
df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")
df = df.dropna()
df = df.drop("customerID", axis=1)

y = df["Churn"].map({"No": 0, "Yes": 1})
X = df.drop("Churn", axis=1)

# change the text columns into numbers
for col in X.select_dtypes(exclude="number").columns:
    X[col] = LabelEncoder().fit_transform(X[col])

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=42, stratify=y)

# decision tree
tree = DecisionTreeClassifier(max_depth=5, random_state=42)
tree.fit(X_train, y_train)
tree_pred = tree.predict(X_test)

# logistic regression to compare
sc = StandardScaler()
X_train_s = sc.fit_transform(X_train)
X_test_s = sc.transform(X_test)
log = LogisticRegression(max_iter=1000)
log.fit(X_train_s, y_train)
log_pred = log.predict(X_test_s)

print("\nDecision Tree")
print("accuracy:", round(accuracy_score(y_test, tree_pred), 3))
print("precision:", round(precision_score(y_test, tree_pred), 3))
print("recall:", round(recall_score(y_test, tree_pred), 3))
print("f1:", round(f1_score(y_test, tree_pred), 3))

print("\nLogistic Regression")
print("accuracy:", round(accuracy_score(y_test, log_pred), 3))
print("precision:", round(precision_score(y_test, log_pred), 3))
print("recall:", round(recall_score(y_test, log_pred), 3))
print("f1:", round(f1_score(y_test, log_pred), 3))

# see which columns matter most
importance = pd.Series(tree.feature_importances_, index=X.columns).sort_values(ascending=False)
print("\ntop features:")
print(importance.head(5).round(3))

importance.head(8).sort_values().plot(kind="barh")
plt.title("Top features for churn")
plt.xlabel("importance")
plt.tight_layout()
plt.savefig("figures/feature_importance.png", dpi=150)
plt.close()

# confusion matrix
cm = confusion_matrix(y_test, tree_pred)
plt.imshow(cm, cmap="Blues")
plt.title("Confusion Matrix")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.xticks([0, 1], ["No", "Yes"])
plt.yticks([0, 1], ["No", "Yes"])
for i in range(2):
    for j in range(2):
        plt.text(j, i, cm[i][j], ha="center", va="center")
plt.tight_layout()
plt.savefig("figures/confusion_matrix.png", dpi=150)
plt.close()

print("\ndone, plots saved in figures folder")
