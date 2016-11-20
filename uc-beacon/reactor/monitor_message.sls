{# Example of Jinja2 #}
{% if data['data']['match'] == 'yes' %}
{% set message = data['data']['raw'] %}

write_message_to_log:
   local.cmd.run:
     - tgt: '*'
     - arg:
        - 'echo "Restarting random deamon because of error: {{ message }}" >> /tmp/random_process_restart.log'

{% endif %}
