default:
	rm -rf tmp
	rvm ruby-head do ruby generator.rb

show:
	rifle result.pdf

make-book:
	pdftk input result.pdf cat 1-endeast output rotate.pdf
	pdfbook2 -p letter rotate.pdf
