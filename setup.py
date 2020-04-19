# SPDX-FileCopyrightText: 2020 The cython-iscsi Authors
#
# SPDX-License-Identifier: LGPL-2.1-or-later

from setuptools import Extension, find_packages, setup

import pkgconfig
import setuptools_scm  # noqa: F401  # Ensure it's present.
from Cython.Build import cythonize

if not pkgconfig.installed("libiscsi", ">=1.13"):
    raise Exception(
        "libiscsi 1.13 not found, make sure you installed libiscsi-dev package, or equivalent"
    )

libiscsi_pkg = pkgconfig.parse("libiscsi")

setup(
    packages=find_packages(),
    package_data={"": ["*.pyx", "*.pxd"]},
    ext_modules=cythonize(
        Extension(name="iscsi", sources=["src/iscsi.pyx"], **libiscsi_pkg)
    ),
    extras_require={
        "dev": [
            "Cython",
            "mypy",
            "pkgconfig",
            "pre-commit",
            "pytest",
            "setuptools>=42",
            "setuptools_scm[toml]>=3.4",
            "wheel",
        ]
    },
)
