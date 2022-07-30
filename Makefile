.PHONY: apply user
.DEFAULT-GOAL: apply

apply:
	ansible-playbook all.yml -i inventory.yml

user:
	wg genkey | tee private.tmp | wg pubkey > public.tmp
	printf "username:\n  private: %s\n  public: %s\n" "$$(cat private.tmp)" "$$(cat public.tmp)" | xsel -ib
	echo "Key is generated and copied!"
	rm -f private.tmp public.tmp
