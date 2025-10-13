PYTHON ?= python3

clean:
	$(PYTHON) setup.py clean
	-find . -name '*.pyc' -delete
	-find . -name '__pycache__' -type d -delete

release-pypi: clean
	# better safe than sorry
	test ! -e dist
	python setup.py sdist
	python setup.py bdist_wheel --universal
	twine upload dist/*
