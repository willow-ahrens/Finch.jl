TEXFLAGS= -shell-escape -synctex=1 -interaction=nonstopmode -file-line-error -pdf

all:levels-A-matrix.png levels-A-d-d-e.png levels-A-d-sl-e.png levels-A-sl-sl-e.png figure-csc-format.png logo.png favicon.ico

%.png: %.pdf # requires ImageMagick
	convert -density 600x600 $^ -quality 90 -resize 600x600 $@

favicon.ico: icon.png # requires ImageMagick
	convert -background transparent $^ -define icon:auto-resize=16,24,32,48,64,72,96,128,256 $@

%.pdf: %.tex # requires TexShop
	latexmk $(TEXFLAGS) $^

clean:  ## Clean output files
	rm -rf *.bbl
	rm -rf *.blg
	rm -rf *.idx
	rm -rf *.ind
	rm -rf *.lof
	rm -rf *.lot
	rm -rf *.out
	rm -rf *.toc
	rm -rf *.acn
	rm -rf *.acr
	rm -rf *.alg
	rm -rf *.glg
	rm -rf *.glo
	rm -rf *.gls
	rm -rf *.fls
	rm -rf *.log
	rm -rf *.fdb_latexmk
	rm -rf *.snm
	rm -rf *.synctex\(busy\)
	rm -rf *.synctex.gz\(busy\)
	rm -rf *.nav
	rm -rf *.aux
	rm -rf *.thm
	rm -rf *.synctex.gz
	rm -rf *.dvi
	rm -rf *.xcp
