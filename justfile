
default:
    @just --list

create target="all":
    ansible-playbook playbook/create_aws.yaml -e target_name={{target}}

create-check target="all":
    ansible-playbook playbook/create_aws.yaml -e target_name={{target}} --check

stop target="all":
    ansible-playbook playbook/stop_aws.yaml -e target_name={{target}}

delete-check target="all":
    ansible-playbook playbook/delete_aws.yaml -e target_name={{target}} --check

delete target="all":
    ansible-playbook playbook/delete_aws.yaml -e target_name={{target}}

inventory:
    ansible-playbook playbook/create_aws.yaml --tags inventory

ping:
    ansible aws_lab2 -m ping

list:
    ansible-inventory -i inventory.ini --graph

# Start all or one EC2
start target="all":
    ansible-playbook playbook/start_aws.yaml -e target_name={{target}}
