#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

import pathlib
import tempfile
import unittest
from unittest.mock import patch

import sign_macos_binaries as signing


class SigningTests(unittest.TestCase):
    @patch.object(signing.sys, "platform", "darwin")
    @patch.object(signing, "is_executable_macho", return_value=True)
    def test_final_app_signature_keeps_developer_id_entitlements(self, _is_executable):
        with tempfile.TemporaryDirectory() as folder:
            framework = pathlib.Path(folder).resolve() / "Python.framework"
            app = framework / "Python.app"
            executable = app / "Contents/MacOS/Python"
            executable.parent.mkdir(parents=True)
            executable.write_bytes(b"\xfe\xed\xfa\xcf")
            entitlements = framework.parent / "entitlements.plist"
            entitlements.write_text("fixture")

            for identity in ("Developer ID Application: Test", "-"):
                arguments = ["sign", str(framework), "--identity", identity, "--entitlements", str(entitlements)]
                with self.subTest(identity=identity), patch.object(signing.sys, "argv", arguments), patch.object(signing, "run") as run:
                    self.assertEqual(signing.main(), 0)
                    commands = [call.args[0] for call in run.call_args_list if "--sign" in call.args[0]]
                    self.assertEqual([command[-1] for command in commands], list(map(str, [executable, app, framework])))
                    for command in commands:
                        self.assertEqual("--timestamp" in command, identity != "-")
                        self.assertEqual("runtime" in command, identity != "-")
                        self.assertEqual("--entitlements" in command, identity != "-" and command[-1] != str(framework))
                        if "--entitlements" in command:
                            self.assertEqual(command[command.index("--entitlements") + 1], str(entitlements))
