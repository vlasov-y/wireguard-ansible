# Took from https://github.com/kubernetes-sigs/kubespray
mitogen:
	ansible-playbook -c local mitogen.yml -vv
clean:
	rm -rf dist/
	rm *.retry
