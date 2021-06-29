#
# Copyright (c) Contributors to the Open 3D Engine Project
# 
#  SPDX-License-Identifier: Apache-2.0 OR MIT
#

import platform

if platform.system() == 'Windows':
    from tempfile import TemporaryDirectory
    from pathlib import Path
    import os
    import stat

    realTempdirCleanup = TemporaryDirectory.cleanup
    def cleanup(self):
        """
        Make files writable before removing them

        In Windows and with Python < 3.8, TemporaryDirectory() will fail to clean up files that are read-only. Git marks
        files in the object store as read-only, so running git clone in a tempdir will fail. This wrapper marks files as
        writable before the cleanup runs.
        """
        for (dirpath, dirnames, filenames) in os.walk(self.name):
            for filename in filenames:
                (Path(dirpath) / filename).chmod(stat.S_IWRITE)
        realTempdirCleanup(self)
    TemporaryDirectory.cleanup = cleanup
