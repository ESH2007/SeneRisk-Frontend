"""Sube tools/maps/out/*.pmtiles y manifest.json al bucket público `mapas` de Supabase Storage.
Requiere las variables SUPABASE_S3_* (backend/.env) y boto3 (está en backend/requirements.txt).
Omite los archivos que ya existen con el mismo tamaño."""
import json
import os
from pathlib import Path

import boto3

s3 = boto3.client(
    "s3",
    endpoint_url=os.environ["SUPABASE_S3_ENDPOINT"],
    region_name=os.environ.get("SUPABASE_S3_REGION", "us-east-1"),
    aws_access_key_id=os.environ["SUPABASE_S3_ACCESS_KEY"],
    aws_secret_access_key=os.environ["SUPABASE_S3_SECRET_KEY"],
)
out = Path(__file__).parent / "out"
build = json.loads((out / "manifest.json").read_text())["build"]
existentes = {o["Key"]: o["Size"] for o in s3.list_objects_v2(Bucket="mapas", Prefix=f"{build}/").get("Contents", [])}
for f in sorted(out.glob("*.pmtiles")):
    key = f"{build}/{f.name}"
    if existentes.get(key) == f.stat().st_size:
        print("ya está:", key)
        continue
    with open(f, "rb") as fh:
        s3.put_object(Bucket="mapas", Key=key, Body=fh, ContentType="application/vnd.pmtiles",
                      CacheControl="public, max-age=31536000, immutable")
    print(f"subido: {key} ({f.stat().st_size / 1048576:.1f} MB)")
s3.put_object(Bucket="mapas", Key="manifest.json", Body=(out / "manifest.json").read_bytes(),
              ContentType="application/json", CacheControl="no-cache")
print("subido: manifest.json")
