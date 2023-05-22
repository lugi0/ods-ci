import base64
import importlib
import json
import os
import sys

import kfp_tekton
from DataSciencePipelinesAPI import DataSciencePipelinesAPI
from robotlibcore import keyword


class DataSciencePipelinesKfpTekton:
    # init should not have a call to external system, otherwise dry-run will fail
    def __init__(self):
        self.client = None
        self.api = None

    def get_client(self, user, pwd, project):
        if self.client is None:
            self.api = DataSciencePipelinesAPI()
            self.api.login_using_user_and_password(user, pwd, project)
            self.client = kfp_tekton.TektonClient(
                host=f"https://{self.api.route}/",
                existing_token=self.api.sa_token,
                ssl_ca_cert=self.get_cert(self.api),
            )
        return self.client, self.api

    def get_cert(self, api):
        cert_json, _ = api.run_oc(
            "oc get secret -n openshift-ingress-operator router-ca -o json"
        )
        cert = json.loads(cert_json)["data"]["tls.crt"]
        decoded_cert = base64.b64decode(cert).decode("utf-8")

        file_name = "/tmp/kft-cert"
        cert_file = open(file_name, "w")
        cert_file.write(decoded_cert)
        cert_file.close()
        return file_name

    def import_souce_code(self, path):
        module_name = os.path.basename(path).replace("-", "_")
        spec = importlib.util.spec_from_loader(
            module_name, importlib.machinery.SourceFileLoader(module_name, path)
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        sys.modules[module_name] = module
        return module

    @keyword
    def kfp_tekton_create_run_from_pipeline_func(
        self, user, pwd, project, source_code, fn
    ):
        client, _ = self.get_client(user, pwd, project)
        # the current path is from where you are running the script
        # sh ods_ci/run_robot_test.sh
        # the current_path will be ods-ci
        current_path = os.getcwd()
        my_source = self.import_souce_code(
            f"{current_path}/ods_ci/tests/Resources/Files/pipeline-samples/{source_code}"
        )
        pipeline = getattr(my_source, fn)
        # create_run_from_pipeline_func will compile the code
        # if you need to see the yaml, for debugging purpose, call: TektonCompiler().compile(pipeline, f'{fn}.yaml')
        result = client.create_run_from_pipeline_func(
            pipeline_func=pipeline, arguments={}
        )
        # easy to debug and double check failures
        print(result)
        return result

    # we are calling DataSciencePipelinesAPI because of https://github.com/kubeflow/kfp-tekton/issues/1223
    # Waiting for a backport https://github.com/kubeflow/kfp-tekton/pull/1234
    @keyword
    def kfp_tekton_wait_for_run_completion(self, user, pwd, project, run_result):
        _, api = self.get_client(user, pwd, project)
        return api.check_run_status(run_result.run_id)
