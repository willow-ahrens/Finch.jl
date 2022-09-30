TEXFLAGS= -shell-escape -synctex=1 -interaction=nonstopmode -file-line-error -pdf

all: figure-birb-matrix icon logo

figure-birb-matrix: figure-birb-matrix.png
icon: icon.png
logo: logo.png

%.png: %.pdf # requires ImageMagick
	convert -density 600x600 $^ -quality 90 -resize 800x600 $@

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