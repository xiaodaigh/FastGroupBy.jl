using Weave

jmd  = "/mnt/d/julia_dev/FastGroupBy/README.jmd"
out_path = "/mnt/d/julia_dev/FastGroupBy/"
weave(jmd, out_path = out_path, doctype = "pandoc")
