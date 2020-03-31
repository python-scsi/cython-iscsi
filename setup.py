# -*- coding: utf-8 -*-
#
# SPDX-FileCopyrightText: © 2020 The cython-iscsi Authors
# SPDX-License-Identifier: LGPL-2.1+

from setuptools import Extension, find_packages, setup

# Ensure it's present.
import setuptools_scm  # noqa: F401
from Cython.Build import cythonize

setup(
    packages=find_packages(),
    package_data={"": ["*.pyx", "*.pxd"]},
    ext_modules=cythonize(
        Extension(name="iscsi", sources=["src/iscsi.pyx"], libraries=["iscsi"])
    ),
    extras_require={
        "dev": [
            "Cython",
            "mypy",
            "pre-commit",
            "pytest",
            "setuptools>=42",
            "setuptools_scm[toml]>=3.4",
            "wheel",
        ]
    },
)
