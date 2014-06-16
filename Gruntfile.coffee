module.exports = (grunt)->
    require('grunt-recurse')(grunt, __dirname)

    grunt.expandFileArg = (
        prefix = '.',
        base = '**',
        postfix = '*test.coffee'
    )->
        part = (v)->"#{prefix}/#{v}#{postfix}"
        files = grunt.option('files')
        return part(base) unless files
        files.split(',').map (v)-> part(v)

    testFiles = grunt.expandFileArg('lib/')

    grunt.Config =
        mochaTest:
            server:
                options:
                    reporter: 'spec'
                src: testFiles
        stassets:
            build: {}
        watch:
            server:
                files: testFiles
                tasks: [
                    'testServer'
                ]
                options:
                    spawn: false

    grunt.registerTask 'testServer', 'Test the server.', ['mochaTest:server']

    grunt.registerTask 'server', 'Prepare the server.', [
        'testServer'
        # 'copy:server'
    ]

    grunt.registerTask 'default', ['server']

    grunt.loadTasks './tasks'

    grunt.finalize()
