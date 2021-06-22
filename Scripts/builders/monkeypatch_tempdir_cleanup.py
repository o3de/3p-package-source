#
# All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
# its licensors.
#
# For complete copyright and license terms please see the LICENSE at the root of this
# distribution (the "License"). All use of this software is governed by the License,
# or, if provided, by the license below or the license accompanying this file. Do not
# remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
