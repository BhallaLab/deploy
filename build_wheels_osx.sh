#!/bin/bash
set -e
set -x

brew install gsl 
sudo easy_install pip --upgrade || echo "Failed to upgrade pip"

#pip install setuptools --prefix=$HOME/.local 
sudo pip install delocate --upgrade  --user python
sudo pip install twine  --upgrade --user python

export PYTHONPATH=$HOME/.local/lib/python2.7/site-packages:$PYTHONPATH

export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MOOSE_SOURCE_DIR=/tmp/moose-core

# Clone git or update.
if [ ! -d $MOOSE_SOURCE_DIR ]; then
    git clone https://github.com/BhallaLab/moose-core --depth 10 $MOOSE_SOURCE_DIR
else
    cd $MOOSE_SOURCE_DIR && git pull
fi

cd $MOOSE_SOURCE_DIR
mkdir -p _build && cd _build

PLATFORM=$(python -c "import distutils.util; print(distutils.util.get_platform())")
echo "Building wheel for $PLATFORM"
cmake -DVERSION_MOOSE=3.2.0rc1 .. && make -j3 && cd python && python setup.cmake.py bdist_wheel -p $PLATFORM

# Now fix the wheel using delocate.
rm -rf $HOME/wheelhouse
mkdir -p $HOME/wheelhouse
cd $MOOSE_SOURCE_DIR/_build/python/ && delocate-wheel -w $HOME/wheelhouse -v dist/*.whl
ls $HOME/wheelhouse/pymoose*.whl
python -m twine upload -u bhallalab -p $PYPI_PASSWORD_BHALLLAB $HOME/wheelhouse/pymoose*.whl
